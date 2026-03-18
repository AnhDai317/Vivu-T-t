import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vivu_tet/data/interfaces/repositories/ichecklist_repository.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistViewModel extends ChangeNotifier {
  final IChecklistRepository _repo;
  static const _uuid = Uuid();

  ChecklistViewModel(this._repo);

  List<ChecklistCategory> categories = [];
  Map<String, List<ChecklistItem>> itemsByCategory = {};
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String? errorMessage;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get selectedDateKey => _dateKey(selectedDate);

  int get totalDone => itemsByCategory.values
      .expand((list) => list)
      .where((i) => i.done)
      .length;

  int get totalAll =>
      itemsByCategory.values.expand((list) => list).length;

  double get totalProgress =>
      totalAll == 0 ? 0 : totalDone / totalAll;

  int doneInCategory(String catId) =>
      (itemsByCategory[catId] ?? []).where((i) => i.done).length;

  int totalInCategory(String catId) =>
      (itemsByCategory[catId] ?? []).length;

  List<ChecklistItem> itemsOfCategory(String catId) =>
      itemsByCategory[catId] ?? [];

  Future<void> loadCategories() async {
    isLoading = true;
    notifyListeners();
    try {
      categories = await _repo.getCategories();
      await _loadItemsForDate(selectedDate);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Lỗi tải dữ liệu: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate = date;
    notifyListeners();
    await _loadItemsForDate(date);
  }

  Future<void> _loadItemsForDate(DateTime date) async {
    final dateKey = _dateKey(date);
    final items = await _repo.getItemsByDate(dateKey);

    final map = <String, List<ChecklistItem>>{};
    for (final cat in categories) {
      map[cat.id] = [];
    }
    for (final item in items) {
      map.putIfAbsent(item.categoryId, () => []).add(item);
    }
    itemsByCategory = map;
    notifyListeners();
  }

  Future<void> toggleItem(
      String categoryId, String itemId, bool done) async {
    final list = itemsByCategory[categoryId] ?? [];
    final item = list.firstWhere((i) => i.id == itemId);
    item.done = done;
    notifyListeners();

    try {
      await _repo.toggleItem(itemId, done);
    } catch (e) {
      item.done = !done;
      notifyListeners();
    }
  }

  Future<void> addItem(String categoryId, String title) async {
    final newItem = ChecklistItem(
      id: _uuid.v4(),
      categoryId: categoryId,
      title: title,
      itemDate: selectedDateKey,
    );

    itemsByCategory.putIfAbsent(categoryId, () => []).add(newItem);
    notifyListeners();

    try {
      await _repo.addItem(newItem);
    } catch (e) {
      itemsByCategory[categoryId]?.removeLast();
      notifyListeners();
    }
  }

  /// Sửa tên item — cập nhật optimistic rồi ghi xuống DB
  Future<void> editItem(
      String categoryId, String itemId, String newTitle) async {
    final list = itemsByCategory[categoryId] ?? [];
    final index = list.indexWhere((i) => i.id == itemId);
    if (index < 0) return;

    final oldTitle = list[index].title;

    // Optimistic update
    list[index].title = newTitle;
    notifyListeners();

    try {
      await _repo.editItem(itemId, newTitle);
    } catch (e) {
      // Rollback
      list[index].title = oldTitle;
      notifyListeners();
    }
  }

  Future<void> deleteItem(String categoryId, String itemId) async {
    final list = itemsByCategory[categoryId] ?? [];
    final index = list.indexWhere((i) => i.id == itemId);
    if (index < 0) return;
    final removed = list[index];

    list.removeAt(index);
    notifyListeners();

    try {
      await _repo.deleteItem(itemId);
    } catch (e) {
      list.insert(index, removed);
      notifyListeners();
    }
  }
}