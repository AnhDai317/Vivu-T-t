// ── PATCH CHO home_viewmodel.dart ────────────────────────────────────────────
// Thêm method reorderActivity() vào class HomeViewModel.
// Các phần còn lại giữ nguyên.
//
// Dán đoạn này vào bên trong class HomeViewModel, sau method deleteActivity()

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

  // ── MỚI: Kéo thả sắp xếp lại thứ tự activities ─────────────────────────
  /// [oldIndex] và [newIndex] là index trong danh sách activities của trip.
  /// ReorderableListView gọi method này sau khi user thả.
  Future<void> reorderActivity({
    required String tripId,
    required int oldIndex,
    required int newIndex,
  }) async {
    // Tìm trip
    final tripIdx = _trips.indexWhere((t) => t.id == tripId);
    if (tripIdx < 0) return;

    final trip = _trips[tripIdx];
    final acts = List<TripActivity>.from(trip.activities);

    // ReorderableListView đặc thù: nếu kéo xuống dưới, newIndex tự động +1
    if (newIndex > oldIndex) newIndex -= 1;

    // Cập nhật optimistic UI ngay lập tức (không chờ DB)
    final moved = acts.removeAt(oldIndex);
    acts.insert(newIndex, moved);

    _trips[tripIdx] = trip.copyWith(activities: acts);
    notifyListeners();

    // Persist xuống DB — cập nhật sort_order từng activity
    try {
      await _tripRepository.reorderActivities(
        tripId: tripId,
        orderedActivityIds: acts.map((a) => a.id).toList(),
      );
    } catch (e) {
      // Rollback nếu lỗi
      _trips[tripIdx] = trip;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addActivityFromDestination({
    required String tripId,
    required String activityTitle,
    required String location,
    required int hour,
    required int minute,
  }) async {
    try {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await _tripRepository.addActivity(
        tripId: tripId,
        activityId: id,
        hour: hour,
        minute: minute,
        title: activityTitle,
        location: location,
      );
      await loadTrips();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
