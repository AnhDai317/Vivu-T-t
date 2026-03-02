import '../../../domain/entities/trip.dart';

abstract class ITripRepository {
  Future<List<Trip>> getTrips();
  Future<void> createTrip(Trip trip);
  Future<void> deleteTrip(String tripId);
}
