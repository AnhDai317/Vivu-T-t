import 'package:sqflite/sqflite.dart';
import 'package:vivu_tet/data/implementations/local/app_database.dart';
import 'package:vivu_tet/data/interfaces/repositories/itrip_repository.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/domain/entities/trip_activity.dart';

class TripRepository implements ITripRepository {
  final AppDatabase database;
  TripRepository(this.database);

  @override
  Future<List<Trip>> getTrips() async {
    final db = await database.database;
    final tripRows = await db.query('trips', orderBy: 'start_date ASC');
    final List<Trip> result = [];
    for (final row in tripRows) {
      final tripId = row['id'].toString();
      final actRows = await db.query(
        'trip_activities',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        // ĐỔI: sort theo sort_order thay vì hour/minute
        // Nếu sort_order = 0 cho tất cả (dữ liệu cũ), fallback về hour/minute
        orderBy: 'sort_order ASC, hour ASC, minute ASC',
      );
      final activities = actRows
          .map(
            (a) => TripActivity(
              id: a['id'].toString(),
              tripId: tripId,
              hour: a['hour'] as int,
              minute: a['minute'] as int,
              title: a['title'].toString(),
              location: a['location'].toString(),
            ),
          )
          .toList();
      result.add(
        Trip(
          id: tripId,
          title: row['title'].toString(),
          startDate: DateTime.parse(row['start_date'].toString()),
          endDate: DateTime.parse(row['end_date'].toString()),
          activities: activities,
        ),
      );
    }
    return result;
  }

  @override
  Future<void> createTrip(Trip trip) async {
    final db = await database.database;
    await db.insert('trips', {
      'id': trip.id,
      'title': trip.title,
      'start_date': trip.startDate.toIso8601String(),
      'end_date': trip.endDate.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    for (int i = 0; i < trip.activities.length; i++) {
      final act = trip.activities[i];
      await db.insert('trip_activities', {
        'id': act.id,
        'trip_id': trip.id,
        'hour': act.hour,
        'minute': act.minute,
        'title': act.title,
        'location': act.location,
        'sort_order': i, // lưu sort_order ngay khi tạo
      });
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final db = await database.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  @override
  Future<void> updateTripTitle({
    required String tripId,
    required String newTitle,
  }) async {
    final db = await database.database;
    await db.update(
      'trips',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  @override
  Future<void> updateActivity({
    required String tripId,
    required String activityId,
    required int hour,
    required int minute,
    required String title,
    required String location,
  }) async {
    final db = await database.database;
    await db.update(
      'trip_activities',
      {'hour': hour, 'minute': minute, 'title': title, 'location': location},
      where: 'id = ? AND trip_id = ?',
      whereArgs: [activityId, tripId],
    );
  }

  @override
  Future<void> deleteActivity({
    required String tripId,
    required String activityId,
  }) async {
    final db = await database.database;
    await db.delete(
      'trip_activities',
      where: 'id = ? AND trip_id = ?',
      whereArgs: [activityId, tripId],
    );
  }

  @override
  Future<void> addActivity({
    required String tripId,
    required String activityId,
    required int hour,
    required int minute,
    required String title,
    required String location,
  }) async {
    final db = await database.database;
    // Lấy sort_order max hiện tại để append cuối danh sách
    final result = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM trip_activities WHERE trip_id = ?',
      [tripId],
    );
    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    await db.insert('trip_activities', {
      'id': activityId,
      'trip_id': tripId,
      'hour': hour,
      'minute': minute,
      'title': title,
      'location': location,
      'sort_order': maxOrder + 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── MỚI: Cập nhật sort_order sau khi user kéo thả ─────────────────────
  @override
  Future<void> reorderActivities({
    required String tripId,
    required List<String> orderedActivityIds,
  }) async {
    final db = await database.database;
    // Dùng batch để update tất cả trong 1 transaction
    final batch = db.batch();
    for (int i = 0; i < orderedActivityIds.length; i++) {
      batch.update(
        'trip_activities',
        {'sort_order': i},
        where: 'id = ? AND trip_id = ?',
        whereArgs: [orderedActivityIds[i], tripId],
      );
    }
    await batch.commit(noResult: true);
  }
}
