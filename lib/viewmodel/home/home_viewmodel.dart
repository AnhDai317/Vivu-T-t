import 'package:flutter/material.dart';
import '../../data/interfaces/repositories/itrip_repository.dart';
import '../../domain/entities/trip.dart';

class HomeViewModel extends ChangeNotifier {
  final ITripRepository _tripRepository;
  HomeViewModel(this._tripRepository);

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Ngày được chọn từ Home để TripListScreen auto-select
  DateTime? _selectedTripDate;
  DateTime? get selectedTripDate => _selectedTripDate;

  void setSelectedTripDate(DateTime date) {
    _selectedTripDate = date;
    // Không cần notifyListeners vì chỉ đọc 1 lần rồi clear
  }

  void clearSelectedTripDate() {
    _selectedTripDate = null;
  }

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
}