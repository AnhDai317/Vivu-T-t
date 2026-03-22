import '../../../domain/entities/trip.dart';

abstract class ITripRepository {
  Future<List<Trip>> getTrips();
  Future<void> createTrip(Trip trip);
  Future<void> deleteTrip(String tripId);
  Future<void> updateTripTitle({
    required String tripId,
    required String newTitle,
  });
  Future<void> updateActivity({
    required String tripId,
    required String activityId,
    required int hour,
    required int minute,
    required String title,
    required String location,
  });
  Future<void> deleteActivity({
    required String tripId,
    required String activityId,
  });

  /// Thêm 1 activity đơn lẻ vào trip đã tồn tại
  Future<void> addActivity({
    required String tripId,
    required String activityId,
    required int hour,
    required int minute,
    required String title,
    required String location,
  });
  Future<void> reorderActivities({
    required String tripId,
    required List<String> orderedActivityIds,
  });
}
