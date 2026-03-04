import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vivu_tet/data/interfaces/repositories/ichecklist_repository.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistViewModel extends ChangeNotifier {
  final IChecklistRepository _repo;

  // Sửa: static const thay vì const
  static const _uuid = Uuid();

  ChecklistViewModel(this._repo);

  List<ChecklistCategory> categories = [];
  bool isLoading = false;
  String? errorMessage;

  int get totalDone =>
      categories.expand((c) => c.items).where((i) => i.done).length;

  int get totalAll => categories.expand((c) => c.items).length;

  double get totalProgress => totalAll == 0 ? 0 : totalDone / totalAll;

  Future<void> loadCategories() async {
    isLoading = true;
    notifyListeners();

    try {
      categories = await _repo.getCategories();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Không thể tải checklist: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleItem(String categoryId, String itemId, bool done) async {
    // Cập nhật local ngay để UI mượt
    final cat = categories.firstWhere((c) => c.id == categoryId);
    final item = cat.items.firstWhere((i) => i.id == itemId);
    item.done = done;
    notifyListeners();

    // Sync DB
    try {
      await _repo.toggleItem(itemId, done);
    } catch (e) {
      // Rollback nếu lỗi
      item.done = !done;
      notifyListeners();
    }
  }

  Future<void> addItem(String categoryId, String title) async {
    final newItem = ChecklistItem(
      id: _uuid.v4(),
      categoryId: categoryId,
      title: title,
    );

    // Cập nhật local trước
    final cat = categories.firstWhere((c) => c.id == categoryId);
    cat.items.add(newItem);
    notifyListeners();

    // Sync DB
    try {
      await _repo.addItem(newItem);
    } catch (e) {
      // Rollback
      cat.items.removeLast();
      notifyListeners();
    }
  }

  Future<void> deleteItem(String categoryId, String itemId) async {
    final cat = categories.firstWhere((c) => c.id == categoryId);
    final index = cat.items.indexWhere((i) => i.id == itemId);
    final removed = cat.items[index];

    // Cập nhật local trước
    cat.items.removeAt(index);
    notifyListeners();

    // Sync DB
    try {
      await _repo.deleteItem(itemId);
    } catch (e) {
      // Rollback
      cat.items.insert(index, removed);
      notifyListeners();
    }
  }
}
