import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

abstract class IChecklistRepository {
  Future<List<ChecklistCategory>> getCategories();
  Future<void> toggleItem(String itemId, bool done);
  Future<void> addItem(ChecklistItem item);
  Future<void> deleteItem(String itemId);
}
