import 'package:flutter/material.dart';
import '../../domain/entities/trip.dart';
import '../../data/interfaces/repositories/itrip_repository.dart';

class CreateTripViewModel extends ChangeNotifier {
  final ITripRepository _tripRepository;

  CreateTripViewModel(this._tripRepository);

  final titleController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setDates(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    notifyListeners();
  }

  Future<bool> createTrip() async {
    if (titleController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      _errorMessage = "Vui lòng nhập đầy đủ tên và thời gian chuyến đi.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTrip = Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Tạo ID tạm
        title: titleController.text.trim(),
        startDate: startDate!,
        endDate: endDate!,
      );

      await _tripRepository.createTrip(newTrip);

      _isLoading = false;
      notifyListeners();
      return true; // Thành công
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Có lỗi xảy ra: ${e.toString()}";
      notifyListeners();
      return false; // Thất bại
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }
}
