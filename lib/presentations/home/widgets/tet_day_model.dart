class TetTask {
  final String title;
  final String? note;
  bool isDone;

  TetTask({required this.title, this.note, this.isDone = false});
}

class TetDay {
  final DateTime date;
  final String lunarLabel;
  final String title;
  final String description;
  final String emoji;
  final List<TetTask> tasks;
  final String tag; // 'pre' | 'tet'

  const TetDay({
    required this.date,
    required this.lunarLabel,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tasks,
    required this.tag,
  });
}

/// Tết Bính Ngọ 2026 🐴
/// Mùng 1 = 17/02/2026 dương lịch
final List<TetDay> tetDays = [
  // ── TRƯỚC TẾT ──────────────────────────────────────────────────────────────
  TetDay(
    date: DateTime(2026, 2, 13),
    lunarLabel: '27 tháng Chạp',
    title: 'Tảo mộ & Thăm tổ tiên',
    description:
        'Cả gia đình ra nghĩa trang dọn dẹp, thắp hương mời tổ tiên về ăn Tết cùng con cháu.',
    emoji: '🪔',
    tag: 'pre',
    tasks: [
      TetTask(title: 'Chuẩn bị hoa, nhang, vàng mã'),
      TetTask(title: 'Ra nghĩa trang dọn dẹp phần mộ'),
      TetTask(title: 'Thắp hương mời tổ tiên'),
      TetTask(title: 'Mua đồ cúng về nhà'),
    ],
  ),
  TetDay(
    date: DateTime(2026, 2, 14),
    lunarLabel: '28 tháng Chạp',
    title: 'Dọn nhà & Mua sắm Tết',
    description:
        'Tổng vệ sinh nhà cửa, trang trí hoa mai/đào, mua sắm thực phẩm và đồ cúng.',
    emoji: '🧹',
    tag: 'pre',
    tasks: [
      TetTask(title: 'Tổng vệ sinh nhà từ trong ra ngoài'),
      TetTask(title: 'Trang trí: cây mai/đào, hoa, câu đối đỏ'),
      TetTask(title: 'Mua thực phẩm: gạo nếp, thịt, rau củ'),
      TetTask(title: 'Mua bánh kẹo, mứt Tết, trà'),
      TetTask(title: 'Chuẩn bị phong bao lì xì'),
    ],
  ),
  TetDay(
    date: DateTime(2026, 2, 15),
    lunarLabel: '29 tháng Chạp',
    title: 'Gói bánh & Nấu cỗ',
    description:
        'Cả nhà quây quần gói bánh chưng/bánh tét, nấu các món truyền thống chuẩn bị mâm cỗ tất niên.',
    emoji: '🍱',
    tag: 'pre',
    tasks: [
      TetTask(title: 'Ngâm gạo nếp, đỗ từ tối hôm trước'),
      TetTask(title: 'Gói bánh chưng / bánh tét'),
      TetTask(title: 'Luộc bánh qua đêm'),
      TetTask(title: 'Nấu giò lụa, thịt đông, dưa hành'),
      TetTask(title: 'Chuẩn bị mâm ngũ quả'),
    ],
  ),
  TetDay(
    date: DateTime(2026, 2, 16),
    lunarLabel: '30 tháng Chạp • Tất Niên',
    title: 'Cúng tất niên & Đón giao thừa',
    description:
        'Ngày cuối năm Ất Tỵ – cúng tiễn năm cũ, bữa cơm đoàn viên rồi thức đón giao thừa bước sang năm Bính Ngọ.',
    emoji: '🎆',
    tag: 'pre',
    tasks: [
      TetTask(title: 'Cúng tất niên buổi chiều'),
      TetTask(title: 'Bữa cơm đoàn viên cả gia đình'),
      TetTask(title: 'Chuẩn bị mâm cúng giao thừa ngoài trời'),
      TetTask(title: 'Thức đến 0h đón giao thừa'),
      TetTask(title: 'Xem pháo hoa / bắn pháo hoa trên TV'),
      TetTask(title: 'Hái lộc đầu năm'),
    ],
  ),

  // ── TẾT BÍNH NGỌ 🐴 ────────────────────────────────────────────────────────
  TetDay(
    date: DateTime(2026, 2, 17),
    lunarLabel: 'Mùng 1 Tết',
    title: 'Năm mới Bính Ngọ – Chúc thọ ông bà',
    description:
        'Ngày đầu năm Bính Ngọ 🐴 – con cháu chúc thọ ông bà cha mẹ, nhận lì xì, đi lễ chùa xin chữ đầu năm.',
    emoji: '🧧',
    tag: 'tet',
    tasks: [
      TetTask(title: 'Dậy sớm, mặc áo mới'),
      TetTask(title: 'Cúng mùng 1 đầu năm'),
      TetTask(title: 'Con cháu chúc thọ ông bà, cha mẹ'),
      TetTask(title: 'Phát lì xì cho trẻ em'),
      TetTask(title: 'Đi lễ chùa / nhà thờ'),
      TetTask(title: 'Xin chữ đầu năm'),
      TetTask(title: 'Không quét nhà, không đổ rác (tránh quét lộc)'),
    ],
  ),
  TetDay(
    date: DateTime(2026, 2, 18),
    lunarLabel: 'Mùng 2 Tết',
    title: 'Chúc Tết bên ngoại',
    description:
        'Ngày về thăm nhà ngoại / bên vợ – mang quà biếu, chúc Tết và gặp gỡ họ hàng bên ngoại.',
    emoji: '👨‍👩‍👧‍👦',
    tag: 'tet',
    tasks: [
      TetTask(title: 'Chuẩn bị quà biếu Tết (bánh, rượu, trà)'),
      TetTask(title: 'Về thăm nhà ngoại / bên vợ hoặc chồng'),
      TetTask(title: 'Chúc Tết họ hàng bên ngoại'),
      TetTask(title: 'Chụp ảnh gia đình lưu niệm'),
    ],
  ),
  TetDay(
    date: DateTime(2026, 2, 19),
    lunarLabel: 'Mùng 3 Tết',
    title: 'Thăm thầy cô & Bạn bè',
    description:
        'Ngày tri ân thầy cô, gặp gỡ bạn bè cũ, tiệc tùng cuối xuân. Một số gia đình cúng hóa vàng tiễn tổ tiên.',
    emoji: '🌸',
    tag: 'tet',
    tasks: [
      TetTask(title: 'Đến thăm và chúc Tết thầy cô giáo cũ'),
      TetTask(title: 'Gặp gỡ hội bạn bè – tiệc xuân'),
      TetTask(title: 'Cúng hóa vàng tiễn tổ tiên (tùy gia đình)'),
      TetTask(title: 'Lì xì người thân còn lại'),
    ],
  ),
];
