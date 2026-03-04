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
        orderBy: 'hour ASC, minute ASC',
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

    for (final act in trip.activities) {
      await db.insert('trip_activities', {
        'id': act.id,
        'trip_id': trip.id,
        'hour': act.hour,
        'minute': act.minute,
        'title': act.title,
        'location': act.location,
      });
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final db = await database.database;
    // trip_activities tự xóa theo CASCADE
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }
}
