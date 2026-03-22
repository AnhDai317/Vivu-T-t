import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/domain/entities/trip_activity.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PUBLIC API
// ══════════════════════════════════════════════════════════════════════════════

Future<void> showStoryExporter({
  required BuildContext context,
  required Trip trip,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StoryExporterSheet(trip: trip),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// THEMES
// ══════════════════════════════════════════════════════════════════════════════

class _Theme {
  final String label;
  final Color bgTop;
  final Color bgBot;
  final Color accent;
  final Color textTitle;
  final Color textBody;
  final Color timeBadgeBg;
  final Color timeBadgeText;

  const _Theme({
    required this.label,
    required this.bgTop,
    required this.bgBot,
    required this.accent,
    required this.textTitle,
    required this.textBody,
    required this.timeBadgeBg,
    required this.timeBadgeText,
  });
}

const _themes = [
  _Theme(
    label: '🔴 Tết Đỏ',
    bgTop: Color(0xFFC62828),
    bgBot: Color(0xFF6D0000),
    accent: Color(0xFFFFD700),
    textTitle: Colors.white,
    textBody: Color(0xFFFFE0B2),
    timeBadgeBg: Color(0x33FFD700),
    timeBadgeText: Color(0xFFFFD700),
  ),
  _Theme(
    label: '✨ Vàng Sang',
    bgTop: Color(0xFF3E2723),
    bgBot: Color(0xFF1A0900),
    accent: Color(0xFFFFD700),
    textTitle: Color(0xFFFFD700),
    textBody: Color(0xFFFFF9C4),
    timeBadgeBg: Color(0x33FFD700),
    timeBadgeText: Color(0xFFFFD700),
  ),
  _Theme(
    label: '🌙 Đêm Xuân',
    bgTop: Color(0xFF0A1929),
    bgBot: Color(0xFF001E3C),
    accent: Color(0xFFFF6B6B),
    textTitle: Colors.white,
    textBody: Color(0xFFFFCDD2),
    timeBadgeBg: Color(0x33FF6B6B),
    timeBadgeText: Color(0xFFFF6B6B),
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _StoryExporterSheet extends StatefulWidget {
  final Trip trip;
  const _StoryExporterSheet({required this.trip});

  @override
  State<_StoryExporterSheet> createState() => _StoryExporterSheetState();
}

class _StoryExporterSheetState extends State<_StoryExporterSheet> {
  final _repaintKey = GlobalKey();
  int _themeIdx = 0;
  bool _exporting = false;

  Future<void> _doExport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      // Đợi frame render
      await Future.delayed(const Duration(milliseconds: 120));

      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Không tìm thấy widget để chụp');

      // Render ở pixel ratio cao để ảnh sắc nét
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Không xuất được ảnh PNG');

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/vivutet_story_$ts.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🌸 ${widget.trip.title}\n📅 ${_fmtDate(widget.trip.startDate)}\n\n#ViVuTet #DuXuan2026 #TetBinhNgo',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fmtDate(DateTime d) {
    const m = [
      '',
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final theme = _themes[_themeIdx];

    return Container(
      height: sh * 0.95,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xuất ảnh Story',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Chia sẻ kế hoạch du xuân lên Story',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Theme pills ─────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _themes.length,
              itemBuilder: (_, i) {
                final active = i == _themeIdx;
                return GestureDetector(
                  onTap: () => setState(() => _themeIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _themes[i].label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? const Color(0xFF111111)
                            : Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Preview card ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _StoryCard(trip: widget.trip, theme: theme),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Export button ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _exporting ? null : _doExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.ios_share_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lưu & Chia sẻ Story',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STORY CARD — kích thước cố định 9:16 ~ 360×640
// ══════════════════════════════════════════════════════════════════════════════

class _StoryCard extends StatelessWidget {
  final Trip trip;
  final _Theme theme;

  const _StoryCard({required this.trip, required this.theme});

  static const double _w = 360;
  static const double _h = 640;

  String _fmtDate(DateTime d) {
    const wdays = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    const months = [
      '',
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    final d = trip.startDate;
    return '${wdays[d.weekday]} · ${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final acts = trip.activities.take(6).toList();
    final extraCount = trip.activities.length - 6;

    return SizedBox(
      width: _w,
      height: _h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── BG gradient ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.bgTop, theme.bgBot],
                ),
              ),
            ),

            // ── Decorative blob top-right ─────────────────────────
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.08),
                ),
              ),
            ),
            // ── Decorative blob bottom-left ───────────────────────
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.06),
                ),
              ),
            ),

            // ── Top accent bar ────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.accent,
                      theme.accent.withOpacity(0.4),
                      theme.accent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────────
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branding row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.accent.withOpacity(0.45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏮', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 5),
                              Text(
                                'ViVu Tết 2026',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '🌸',
                          style: TextStyle(
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                color: theme.accent.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Date + shortLabel row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            trip.shortDateLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: theme.bgBot,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _fmtDate(trip.startDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textBody,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Trip title
                    Text(
                      trip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.textTitle,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Accent underline
                    Container(
                      width: 44,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Activities timeline
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: acts.isEmpty
                            ? [
                                Text(
                                  'Chưa có hoạt động',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: theme.textBody,
                                  ),
                                ),
                              ]
                            : [
                                ...acts.asMap().entries.map((e) {
                                  final isLast =
                                      e.key == acts.length - 1 &&
                                      extraCount <= 0;
                                  return _ActivityRow(
                                    activity: e.value,
                                    theme: theme,
                                    isLast: isLast,
                                  );
                                }),
                                if (extraCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const SizedBox(width: 14),
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.accent.withOpacity(0.18),
                                          border: Border.all(
                                            color: theme.accent.withOpacity(
                                              0.45,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '+$extraCount',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: theme.accent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'và $extraCount hoạt động khác',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: theme.textBody,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                      ),
                    ),

                    // Bottom blessing card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.accent.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🧧 Chúc Xuân An Lành 🧧',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: theme.accent,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Vạn sự như ý · Tết Bính Ngọ 2026 🐴',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: theme.textBody,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Hashtags
                    Center(
                      child: Text(
                        '#ViVuTet  #DuXuan2026  #TetBinhNgo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: theme.textBody.withOpacity(0.45),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom accent bar ─────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.accent,
                      theme.accent.withOpacity(0.4),
                      theme.accent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity row trong card ────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final TripActivity activity;
  final _Theme theme;
  final bool isLast;

  const _ActivityRow({
    required this.activity,
    required this.theme,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${activity.hour.toString().padLeft(2, '0')}:${activity.minute.toString().padLeft(2, '0')}';
    // Lấy tên ngắn của location (trước dấu phẩy đầu tiên)
    final locShort = activity.location.contains(',')
        ? activity.location.split(',').first.trim()
        : activity.location;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 26,
                    color: theme.accent.withOpacity(0.22),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.timeBadgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: theme.timeBadgeText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),

                  // Title + loc
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.textTitle,
                          ),
                        ),
                        if (locShort.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 9,
                                color: theme.textBody.withOpacity(0.65),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locShort,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: theme.textBody.withOpacity(0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
