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
      tripId: '',
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
      // ── FIX: Kiểm tra đã có trip cùng ngày chưa ────────────────────────
      final existingTrips = await _tripRepository.getTrips();
      final sel = selectedDate;
      final sameDay = existingTrips
          .where(
            (t) =>
                t.startDate.year == sel.year &&
                t.startDate.month == sel.month &&
                t.startDate.day == sel.day,
          )
          .toList();

      if (sameDay.isNotEmpty) {
        // ── Ngày đã tồn tại: thêm activities vào trip cũ ─────────────────
        final existingTrip = sameDay.first;

        // Tính sort_order tiếp theo
        int maxOrder = existingTrip.activities.length;

        for (int i = 0; i < activities.length; i++) {
          final act = activities[i];
          final newId = '${DateTime.now().microsecondsSinceEpoch}_$i';
          await _tripRepository.addActivity(
            tripId: existingTrip.id,
            activityId: newId,
            hour: act.hour,
            minute: act.minute,
            title: act.title,
            location: act.location,
          );
          maxOrder++;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // ── Ngày chưa tồn tại: tạo trip mới ─────────────────────────────────
      // ID dùng ngày cố định để tránh trùng khi tạo lại cùng ngày
      final tripId =
          'trip_${sel.year}${sel.month.toString().padLeft(2, '0')}${sel.day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';

      final finalActivities = activities
          .asMap()
          .entries
          .map(
            (e) => TripActivity(
              id: '${tripId}_act_${e.key}',
              tripId: tripId,
              hour: e.value.hour,
              minute: e.value.minute,
              title: e.value.title,
              location: e.value.location,
            ),
          )
          .toList();

      final newTrip = Trip(
        id: tripId,
        title: titleController.text.trim(),
        startDate: selectedDate,
        endDate: selectedDate,
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
