import 'package:flutter/material.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_activity.dart';
import '../../data/interfaces/repositories/itrip_repository.dart';

class CreateTripViewModel extends ChangeNotifier {
  final ITripRepository _tripRepository;

  CreateTripViewModel(this._tripRepository);

  final titleController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final List<TripActivity> activities = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void addActivity({
    required int hour,
    required int minute,
    required String title,
    required String location,
  }) {
    final act = TripActivity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      tripId: '', // sẽ được gán khi createTrip
      hour: hour,
      minute: minute,
      title: title,
      location: location,
    );
    activities.add(act);
    activities.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    notifyListeners();
  }

  void removeActivity(int index) {
    activities.removeAt(index);
    notifyListeners();
  }

  Future<bool> createTrip() async {
    if (titleController.text.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên chuyến đi.';
      notifyListeners();
      return false;
    }
    if (activities.isEmpty) {
      _errorMessage = 'Vui lòng thêm ít nhất 1 hoạt động.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tripId = DateTime.now().millisecondsSinceEpoch.toString();

      // Gắn tripId vào activities
      final finalActivities = activities
          .map(
            (a) => TripActivity(
              id: a.id,
              tripId: tripId,
              hour: a.hour,
              minute: a.minute,
              title: a.title,
              location: a.location,
            ),
          )
          .toList();

      final newTrip = Trip(
        id: tripId,
        title: titleController.text.trim(),
        startDate: selectedDate,
        endDate: selectedDate, // 1 ngày nên start = end
        activities: finalActivities,
      );

      await _tripRepository.createTrip(newTrip);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }
}
