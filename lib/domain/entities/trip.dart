import 'trip_activity.dart';

class Trip {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final List<TripActivity> activities;

  Trip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.coverImageUrl,
    this.activities = const [],
  });

  /// Trả về nhãn ngày âm lịch nếu title có chứa "Mùng X" hoặc "M.X"
  /// Tạm thời dùng startDate so với ngày Mùng 1 Tết 2026 (17/02/2026)
  String get shortDateLabel {
    final tet2026 = DateTime(2026, 2, 17);
    final diff = startDate.difference(tet2026).inDays;
    if (diff >= 0 && diff <= 14) {
      return 'M.${diff + 1}';
    }
    // Trả về ngày dương lịch dạng ngắn
    return '${startDate.day}/${startDate.month}';
  }

  bool get isPast => startDate.isBefore(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }
}
