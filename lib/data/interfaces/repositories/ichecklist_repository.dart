import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

abstract class IChecklistRepository {
  Future<List<ChecklistCategory>> getCategories();
  Future<List<ChecklistItem>> getItemsByDate(String date);
  Future<void> toggleItem(String itemId, bool done);
  Future<void> addItem(ChecklistItem item);
  /// Sửa tên item theo id
  Future<void> editItem(String itemId, String newTitle);
  Future<void> deleteItem(String itemId);
}