/// Tiện ích tính ngày Tết âm lịch động.
/// Danh sách ngày Mùng 1 Tết dương lịch được hardcode cho 2025–2035
/// vì không có thư viện âm lịch nhẹ nào đáng tin trong Flutter.
class TetDateUtils {
  TetDateUtils._();

  /// Ngày Mùng 1 Tết âm lịch theo dương lịch
  static Map<int, DateTime> _tet = {
    2025: DateTime.utc(2025, 1, 29),
    2026: DateTime.utc(2026, 2, 17),
    2027: DateTime.utc(2027, 2, 6),
    2028: DateTime.utc(2028, 1, 26),
    2029: DateTime.utc(2029, 2, 13),
    2030: DateTime.utc(2030, 2, 3),
    2031: DateTime.utc(2031, 1, 23),
    2032: DateTime.utc(2032, 2, 11),
    2033: DateTime.utc(2033, 1, 31),
    2034: DateTime.utc(2034, 2, 19),
    2035: DateTime.utc(2035, 2, 8),
  };

  /// Tên can chi theo năm dương lịch
  static const List<String> _can = [
    'Canh',
    'Tân',
    'Nhâm',
    'Quý',
    'Giáp',
    'Ất',
    'Bính',
    'Đinh',
    'Mậu',
    'Kỷ',
  ];
  static const List<String> _chi = [
    'Thân',
    'Dậu',
    'Tuất',
    'Hợi',
    'Tý',
    'Sửu',
    'Dần',
    'Mão',
    'Thìn',
    'Tỵ',
    'Ngọ',
    'Mùi',
    'Thân',
    'Dậu',
    'Tuất',
    'Hợi',
    'Tý',
    'Sửu',
    'Dần',
    'Mão',
    'Thìn',
    'Tỵ',
    'Ngọ',
    'Mùi',
  ];

  /// Con giáp emoji theo chi
  static const Map<String, String> _chiEmoji = {
    'Thân': '🐒',
    'Dậu': '🐓',
    'Tuất': '🐕',
    'Hợi': '🐗',
    'Tý': '🐭',
    'Sửu': '🐂',
    'Dần': '🐯',
    'Mão': '🐰',
    'Thìn': '🐲',
    'Tỵ': '🐍',
    'Ngọ': '🐴',
    'Mùi': '🐑',
  };

  /// Tên can chi của năm âm lịch (năm dương lịch + 1 so với Tết)
  static String canChiOfYear(int lunarYear) {
    final can = _can[lunarYear % 10];
    final chi = _chi[lunarYear % 12];
    return '$can $chi';
  }

  static String? emojiOfYear(int lunarYear) {
    final chi = _chi[lunarYear % 12];
    return _chiEmoji[chi];
  }

  /// Ngày Tết tiếp theo tính từ [now].
  /// Nếu Tết năm nay chưa qua → trả về Tết năm nay.
  /// Nếu đã qua → trả về Tết năm sau.
  static ({DateTime date, int lunarYear}) nextTet({DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);

    for (final entry in _tet.entries) {
      if (!entry.value.isBefore(todayUtc)) {
        // Tết năm âm lịch = năm dương lịch của Tết (vì Tết là tháng 1/2
        // dương lịch, thuộc năm âm lịch bắt đầu từ đó)
        return (date: entry.value, lunarYear: entry.key);
      }
    }

    // Fallback: năm xa nhất trong bảng
    final last = _tet.entries.last;
    return (date: last.value, lunarYear: last.key);
  }

  /// Số ngày còn lại đến Tết tiếp theo (>= 0)
  static int daysUntilNextTet({DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayLocal = DateTime(today.year, today.month, today.day);
    final tet = nextTet(now: now);
    final tetLocal = DateTime(tet.date.year, tet.date.month, tet.date.day);
    final diff = tetLocal.difference(todayLocal).inDays;
    return diff.clamp(0, 99999);
  }
}
