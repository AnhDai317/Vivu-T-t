import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vivu_tet/data/interfaces/repositories/ichecklist_repository.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistViewModel extends ChangeNotifier {
  final IChecklistRepository _repo;
  static const _uuid = Uuid();

  ChecklistViewModel(this._repo);

  // Danh sách categories (chỉ metadata, không có items)
  List<ChecklistCategory> categories = [];

  // Items của ngày đang chọn, group theo categoryId
  Map<String, List<ChecklistItem>> itemsByCategory = {};

  // Ngày đang xem
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String? errorMessage;

  // Format date thành key 'yyyy-MM-dd'
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get selectedDateKey => _dateKey(selectedDate);

  // Tổng done/total của ngày đang chọn
  int get totalDone => itemsByCategory.values
      .expand((list) => list)
      .where((i) => i.done)
      .length;

  int get totalAll =>
      itemsByCategory.values.expand((list) => list).length;

  double get totalProgress =>
      totalAll == 0 ? 0 : totalDone / totalAll;

  // Done/total theo từng category
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

    // Group theo categoryId
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
    // Optimistic update
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