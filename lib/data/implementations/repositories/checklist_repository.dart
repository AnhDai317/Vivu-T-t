import 'package:vivu_tet/data/implementations/local/app_database.dart';
import 'package:vivu_tet/data/interfaces/repositories/ichecklist_repository.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistRepository implements IChecklistRepository {
  final AppDatabase _db;
  ChecklistRepository(this._db);

  @override
  Future<List<ChecklistCategory>> getCategories() async {
    final db = await _db.database;
    final catMaps = await db.query(
      'checklist_categories',
      orderBy: 'sort_order ASC',
    );
    // Trả về categories rỗng items — items load riêng theo ngày
    return catMaps
        .map((m) => ChecklistCategory(
              id: m['id'] as String,
              icon: m['icon'] as String,
              title: m['title'] as String,
              colorValue: m['color_value'] as int,
              items: [],
            ))
        .toList();
  }

  @override
  Future<List<ChecklistItem>> getItemsByDate(String date) async {
    final db = await _db.database;
    final maps = await db.query(
      'checklist_items',
      where: 'item_date = ?',
      whereArgs: [date],
      orderBy: 'sort_order ASC',
    );
    return maps
        .map((m) => ChecklistItem(
              id: m['id'] as String,
              categoryId: m['category_id'] as String,
              title: m['title'] as String,
              itemDate: m['item_date'] as String,
              done: (m['done'] as int) == 1,
            ))
        .toList();
  }

  @override
  Future<void> toggleItem(String itemId, bool done) async {
    final db = await _db.database;
    await db.update(
      'checklist_items',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  @override
  Future<void> addItem(ChecklistItem item) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM checklist_items WHERE category_id = ? AND item_date = ?',
      [item.categoryId, item.itemDate],
    );
    final maxOrder = (result.first['max_order'] as int?) ?? -1;
    await db.insert('checklist_items', {
      'id': item.id,
      'category_id': item.categoryId,
      'title': item.title,
      'done': 0,
      'sort_order': maxOrder + 1,
      'item_date': item.itemDate,
    });
  }

  @override
  Future<void> deleteItem(String itemId) async {
    final db = await _db.database;
    await db.delete(
      'checklist_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}