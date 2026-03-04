import 'package:uuid/uuid.dart';
import 'package:vivu_tet/data/implementations/local/app_database.dart';
import 'package:vivu_tet/data/interfaces/repositories/ichecklist_repository.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistRepository implements IChecklistRepository {
  final AppDatabase _db;
  const ChecklistRepository(this._db);

  @override
  Future<List<ChecklistCategory>> getCategories() async {
    final db = await _db.database;

    final catMaps = await db.query(
      'checklist_categories',
      orderBy: 'sort_order ASC',
    );

    final categories = <ChecklistCategory>[];

    for (final catMap in catMaps) {
      final itemMaps = await db.query(
        'checklist_items',
        where: 'category_id = ?',
        whereArgs: [catMap['id']],
        orderBy: 'sort_order ASC',
      );

      categories.add(
        ChecklistCategory(
          id: catMap['id'] as String,
          icon: catMap['icon'] as String,
          title: catMap['title'] as String,
          colorValue: catMap['color_value'] as int,
          items: itemMaps
              .map(
                (m) => ChecklistItem(
                  id: m['id'] as String,
                  categoryId: m['category_id'] as String,
                  title: m['title'] as String,
                  done: (m['done'] as int) == 1,
                ),
              )
              .toList(),
        ),
      );
    }

    return categories;
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

    // Lấy sort_order max hiện tại trong category
    final result = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM checklist_items WHERE category_id = ?',
      [item.categoryId],
    );
    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    await db.insert('checklist_items', {
      'id': item.id,
      'category_id': item.categoryId,
      'title': item.title,
      'done': 0,
      'sort_order': maxOrder + 1,
    });
  }

  @override
  Future<void> deleteItem(String itemId) async {
    final db = await _db.database;
    await db.delete('checklist_items', where: 'id = ?', whereArgs: [itemId]);
  }
}
