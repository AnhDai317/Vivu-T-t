import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

abstract class IChecklistRepository {
  Future<List<ChecklistCategory>> getCategories();
  // Lấy items theo ngày cụ thể
  Future<List<ChecklistItem>> getItemsByDate(String date);
  Future<void> toggleItem(String itemId, bool done);
  Future<void> addItem(ChecklistItem item);
  Future<void> deleteItem(String itemId);
}