import 'package:flutter/material.dart';
import '../../data/interfaces/repositories/itrip_repository.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_activity.dart';

class HomeViewModel extends ChangeNotifier {
  final ITripRepository _tripRepository;
  HomeViewModel(this._tripRepository);

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DateTime? _selectedTripDate;
  DateTime? get selectedTripDate => _selectedTripDate;

  void setSelectedTripDate(DateTime date) {
    _selectedTripDate = date;
    notifyListeners();
  }

  void clearSelectedTripDate() => _selectedTripDate = null;

  Future<void> loadTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _trips = await _tripRepository.getTrips();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripRepository.deleteTrip(tripId);
      _trips.removeWhere((t) => t.id == tripId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTripTitle({
    required String tripId,
    required String newTitle,
  }) async {
    try {
      await _tripRepository.updateTripTitle(tripId: tripId, newTitle: newTitle);
      await loadTrips();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateActivity({
    required String tripId,
    required String activityId,
    required int hour,
    required int minute,
    required String title,
    required String location,
  }) async {
    try {
      await _tripRepository.updateActivity(
        tripId: tripId,
        activityId: activityId,
        hour: hour,
        minute: minute,
        title: title,
        location: location,
      );
      await loadTrips();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteActivity({
    required String tripId,
    required String activityId,
  }) async {
    try {
      await _tripRepository.deleteActivity(
        tripId: tripId,
        activityId: activityId,
      );
      await loadTrips();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
