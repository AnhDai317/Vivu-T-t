import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vivu_tet/data/interfaces/repositories/ichecklist_repository.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistViewModel extends ChangeNotifier {
  final IChecklistRepository _repo;
  static const _uuid = Uuid();

  /// Key đặc biệt cho tab "Công việc chung" (không gắn ngày)
  static const String generalDateKey = 'general';

  ChecklistViewModel(this._repo);

  List<ChecklistCategory> categories = [];
  Map<String, List<ChecklistItem>> itemsByCategory = {};

  DateTime selectedDate = DateTime.now();

  /// true = đang xem tab "Công việc chung"
  bool isGeneralMode = false;

  bool isLoading = false;
  String? errorMessage;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get selectedDateKey =>
      isGeneralMode ? generalDateKey : _dateKey(selectedDate);

  // ── Thống kê ──────────────────────────────────────────────────────────────
  int get totalDone =>
      itemsByCategory.values.expand((l) => l).where((i) => i.done).length;

  int get totalAll => itemsByCategory.values.expand((l) => l).length;

  double get totalProgress => totalAll == 0 ? 0 : totalDone / totalAll;

  int doneInCategory(String catId) =>
      (itemsByCategory[catId] ?? []).where((i) => i.done).length;

  int totalInCategory(String catId) => (itemsByCategory[catId] ?? []).length;

  List<ChecklistItem> itemsOfCategory(String catId) =>
      itemsByCategory[catId] ?? [];

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> loadCategories() async {
    isLoading = true;
    notifyListeners();
    try {
      categories = await _repo.getCategories();
      await _loadItemsForDateKey(selectedDateKey);
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
    isGeneralMode = false;
    notifyListeners();
    await _loadItemsForDateKey(_dateKey(date));
  }

  /// Chuyển sang tab Công việc chung
  Future<void> switchToGeneral() async {
    isGeneralMode = true;
    notifyListeners();
    await _loadItemsForDateKey(generalDateKey);
  }

  /// Chuyển về tab theo ngày
  Future<void> switchToDate() async {
    isGeneralMode = false;
    notifyListeners();
    await _loadItemsForDateKey(_dateKey(selectedDate));
  }

  Future<void> _loadItemsForDateKey(String dateKey) async {
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

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> toggleItem(String categoryId, String itemId, bool done) async {
    final list = itemsByCategory[categoryId] ?? [];
    final item = list.firstWhere((i) => i.id == itemId);
    item.done = done;
    notifyListeners();
    try {
      await _repo.toggleItem(itemId, done);
    } catch (_) {
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
    } catch (_) {
      itemsByCategory[categoryId]?.removeLast();
      notifyListeners();
    }
  }

  Future<void> editItem(
    String categoryId,
    String itemId,
    String newTitle,
  ) async {
    final list = itemsByCategory[categoryId] ?? [];
    final idx = list.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    final old = list[idx].title;
    list[idx].title = newTitle;
    notifyListeners();
    try {
      await _repo.editItem(itemId, newTitle);
    } catch (_) {
      list[idx].title = old;
      notifyListeners();
    }
  }

  /// Xoá item và trả về item đã xoá để caller có thể Undo
  Future<ChecklistItem?> deleteItem(String categoryId, String itemId) async {
    final list = itemsByCategory[categoryId] ?? [];
    final idx = list.indexWhere((i) => i.id == itemId);
    if (idx < 0) return null;
    final removed = list[idx];
    list.removeAt(idx);
    notifyListeners();
    try {
      await _repo.deleteItem(itemId);
      return removed;
    } catch (_) {
      list.insert(idx, removed);
      notifyListeners();
      return null;
    }
  }

  /// Khôi phục item đã xoá (Undo)
  Future<void> undoDelete(String categoryId, ChecklistItem item) async {
    itemsByCategory.putIfAbsent(categoryId, () => []).add(item);
    notifyListeners();
    try {
      await _repo.addItem(item);
    } catch (_) {
      itemsByCategory[categoryId]?.removeWhere((i) => i.id == item.id);
      notifyListeners();
    }
  }
}
