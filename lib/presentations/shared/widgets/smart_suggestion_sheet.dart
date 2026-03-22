import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/domain/entities/weather.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

// ── Model ──────────────────────────────────────────────────────────────────────
class ChecklistSuggestion {
  final String emoji;
  final String title;
  final String categoryId;
  const ChecklistSuggestion({
    required this.emoji,
    required this.title,
    required this.categoryId,
  });
}

// ── Engine phân tích ───────────────────────────────────────────────────────────
class SmartSuggestionEngine {
  static List<ChecklistSuggestion> analyze({
    required Trip trip,
    required Weather? weather,
  }) {
    final raw = <ChecklistSuggestion>[];
    final all = [
      ...trip.activities.map((a) => a.title.toLowerCase()),
      ...trip.activities.map((a) => a.location.toLowerCase()),
    ].join(' ');

    // ── Thời tiết ────────────────────────────────────────────────────
    if (weather != null) {
      final desc = weather.description.toLowerCase();
      final temp = weather.temperature;
      if (desc.contains('mưa') ||
          desc.contains('dông') ||
          desc.contains('phùn')) {
        raw.addAll([
          const ChecklistSuggestion(
            emoji: '☂️',
            title: 'Ô / áo mưa',
            categoryId: 'cat_4',
          ),
          const ChecklistSuggestion(
            emoji: '👟',
            title: 'Giày chống nước',
            categoryId: 'cat_4',
          ),
        ]);
      }
      if (desc.contains('sương') || temp < 18) {
        raw.addAll([
          const ChecklistSuggestion(
            emoji: '🧥',
            title: 'Áo khoác ấm',
            categoryId: 'cat_4',
          ),
          const ChecklistSuggestion(
            emoji: '🧣',
            title: 'Khăn quàng cổ',
            categoryId: 'cat_4',
          ),
        ]);
      }
      if (temp > 27 || desc.contains('quang') || desc.contains('ít mây')) {
        raw.addAll([
          const ChecklistSuggestion(
            emoji: '🕶️',
            title: 'Kính mát chống UV',
            categoryId: 'cat_4',
          ),
          const ChecklistSuggestion(
            emoji: '🧴',
            title: 'Kem chống nắng SPF50',
            categoryId: 'cat_4',
          ),
          const ChecklistSuggestion(
            emoji: '🎩',
            title: 'Mũ / nón rộng vành',
            categoryId: 'cat_4',
          ),
        ]);
      }
    }

    // ── Chùa / Đền / Lễ ─────────────────────────────────────────────
    if (_has(all, ['chùa', 'đền', 'phủ', 'miếu', 'lễ', 'thờ', 'lăng'])) {
      raw.addAll([
        const ChecklistSuggestion(
          emoji: '💵',
          title: 'Tiền lẻ công đức',
          categoryId: 'cat_1',
        ),
        const ChecklistSuggestion(
          emoji: '📜',
          title: 'Sớ / vàng mã',
          categoryId: 'cat_1',
        ),
        const ChecklistSuggestion(
          emoji: '👘',
          title: 'Trang phục kín đáo',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '🏮',
          title: 'Hoa tươi cúng lễ',
          categoryId: 'cat_1',
        ),
      ]);
    }

    // ── Ăn uống ──────────────────────────────────────────────────────
    if (_has(all, [
      'ăn',
      'nhà hàng',
      'quán',
      'phở',
      'bún',
      'lẩu',
      'tiệc',
      'cơm',
      'bbq',
      'kem',
      'cà phê',
    ])) {
      raw.addAll([
        const ChecklistSuggestion(
          emoji: '💊',
          title: 'Thuốc dạ dày / tiêu hoá',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '💳',
          title: 'Ví / thẻ thanh toán',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '🤳',
          title: 'Điện thoại sạc đầy (chụp ảnh)',
          categoryId: 'cat_4',
        ),
      ]);
    }

    // ── Đi xa / Ngoại ô ──────────────────────────────────────────────
    if (_has(all, [
      'sơn tây',
      'đường lâm',
      'bát tràng',
      'ba vì',
      'suối',
      'làng',
      'km',
      'khởi hành',
      'ngoại ô',
      'chuyến',
    ])) {
      raw.addAll([
        const ChecklistSuggestion(
          emoji: '⛽',
          title: 'Đổ đầy xăng xe',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '🗺️',
          title: 'Tải bản đồ offline',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '🍱',
          title: 'Đồ ăn nhẹ đường dài',
          categoryId: 'cat_3',
        ),
        const ChecklistSuggestion(
          emoji: '💧',
          title: 'Nước uống (1.5L)',
          categoryId: 'cat_3',
        ),
        const ChecklistSuggestion(
          emoji: '🏥',
          title: 'Thuốc say xe',
          categoryId: 'cat_4',
        ),
      ]);
    }

    // ── Mua sắm / Chợ ────────────────────────────────────────────────
    if (_has(all, [
      'chợ',
      'mua',
      'quà',
      'sắm',
      'lụa',
      'gốm',
      'đặc sản',
      'hàng buồm',
      'đồng xuân',
    ])) {
      raw.addAll([
        const ChecklistSuggestion(
          emoji: '🛍️',
          title: 'Túi tote đựng đồ',
          categoryId: 'cat_1',
        ),
        const ChecklistSuggestion(
          emoji: '📦',
          title: 'Hộp / giấy gói quà',
          categoryId: 'cat_1',
        ),
        const ChecklistSuggestion(
          emoji: '💰',
          title: 'Tiền mặt tiêu vặt',
          categoryId: 'cat_1',
        ),
      ]);
    }

    // ── Check-in / View đẹp ───────────────────────────────────────────
    if (_has(all, [
      'check-in',
      'view',
      'bar',
      'observation',
      'hoàng hôn',
      'ngắm',
      'cầu',
      'bình minh',
    ])) {
      raw.addAll([
        const ChecklistSuggestion(
          emoji: '🔋',
          title: 'Pin dự phòng',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '🤳',
          title: 'Gậy selfie / tripod nhỏ',
          categoryId: 'cat_4',
        ),
      ]);
    }

    // ── Outdoor / Hồ / Đi bộ ─────────────────────────────────────────
    if (_has(all, ['hồ', 'công viên', 'đạp xe', 'đi bộ', 'đi dạo'])) {
      raw.addAll([
        const ChecklistSuggestion(
          emoji: '👟',
          title: 'Giày thể thao thoải mái',
          categoryId: 'cat_4',
        ),
        const ChecklistSuggestion(
          emoji: '🧢',
          title: 'Mũ lưỡi trai',
          categoryId: 'cat_4',
        ),
      ]);
    }

    // ── Essentials luôn thêm ──────────────────────────────────────────
    raw.addAll([
      const ChecklistSuggestion(
        emoji: '🪪',
        title: 'CMND / CCCD',
        categoryId: 'cat_4',
      ),
      const ChecklistSuggestion(
        emoji: '🔑',
        title: 'Chìa khoá nhà / xe',
        categoryId: 'cat_4',
      ),
      const ChecklistSuggestion(
        emoji: '🩹',
        title: 'Băng dán / thuốc cơ bản',
        categoryId: 'cat_4',
      ),
      const ChecklistSuggestion(
        emoji: '📱',
        title: 'Điện thoại sạc đầy',
        categoryId: 'cat_4',
      ),
    ]);

    // Dedup theo title
    final seen = <String>{};
    return raw.where((s) => seen.add(s.title)).toList();
  }

  static bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}

// ── Bottom Sheet ───────────────────────────────────────────────────────────────
class SmartSuggestionSheet extends StatefulWidget {
  final Trip trip;
  final Weather? weather;
  final void Function(List<ChecklistSuggestion>) onAddSelected;

  const SmartSuggestionSheet({
    super.key,
    required this.trip,
    required this.weather,
    required this.onAddSelected,
  });

  @override
  State<SmartSuggestionSheet> createState() => _SmartSuggestionSheetState();
}

class _SmartSuggestionSheetState extends State<SmartSuggestionSheet> {
  late final List<ChecklistSuggestion> _suggestions;
  late final Set<int> _selected;

  static const _catColors = {
    'cat_1': Color(0xFFE53935),
    'cat_2': Color(0xFF43A047),
    'cat_3': Color(0xFFF57C00),
    'cat_4': Color(0xFF1E88E5),
  };
  static const _catLabels = {
    'cat_1': 'Sắm Tết',
    'cat_2': 'Dọn nhà',
    'cat_3': 'Ẩm thực',
    'cat_4': 'Du xuân',
  };

  @override
  void initState() {
    super.initState();
    _suggestions = SmartSuggestionEngine.analyze(
      trip: widget.trip,
      weather: widget.weather,
    );
    // Mặc định chọn tất cả
    _selected = Set.from(List.generate(_suggestions.length, (i) => i));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildList(ctrl)),
            _buildButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final allSelected = _selected.length == _suggestions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý thông minh',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brownDeep,
                      ),
                    ),
                    Text(
                      'Dựa trên lịch trình & thời tiết',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  allSelected
                      ? _selected.clear()
                      : _selected.addAll(
                          List.generate(_suggestions.length, (i) => i),
                        );
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    allSelected ? 'Bỏ chọn' : 'Tất cả',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.weather != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Text(
                    widget.weather!.icon,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.weather!.description} • ${widget.weather!.temperature.toStringAsFixed(0)}°C — ${widget.trip.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade100),
        ],
      ),
    );
  }

  Widget _buildList(ScrollController ctrl) {
    return ListView.builder(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _suggestions.length,
      itemBuilder: (_, i) {
        final s = _suggestions[i];
        final color = _catColors[s.categoryId] ?? AppColors.primary;
        final label = _catLabels[s.categoryId] ?? '';
        final isSel = _selected.contains(i);

        return GestureDetector(
          onTap: () =>
              setState(() => isSel ? _selected.remove(i) : _selected.add(i)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? color.withOpacity(0.06) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? color.withOpacity(0.35) : Colors.grey.shade200,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSel ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? color : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isSel
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(s.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSel ? AppColors.brownDeep : Colors.grey.shade500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context) {
    final count = _selected.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: count == 0
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onAddSelected(
                      _selected.map((i) => _suggestions[i]).toList(),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  count == 0
                      ? 'Chọn ít nhất 1 mục'
                      : 'Thêm $count mục vào Checklist',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: count == 0 ? Colors.grey.shade400 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper function ────────────────────────────────────────────────────────────
Future<void> showSmartSuggestions({
  required BuildContext context,
  required Trip trip,
  required Weather? weather,
  required void Function(List<ChecklistSuggestion>) onAddSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SmartSuggestionSheet(
      trip: trip,
      weather: weather,
      onAddSelected: onAddSelected,
    ),
  );
}
