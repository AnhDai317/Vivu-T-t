import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/presentations/planner/create_trip_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  int _selectedIndex = 0;

  void _confirmDelete(BuildContext context, HomeViewModel vm, Trip trip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xoá kế hoạch?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDeep,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xoá "${trip.title}" không?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.brownMid,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Huỷ',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.brownMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.deleteTrip(trip.id);
              if (mounted) setState(() => _selectedIndex = 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Xoá',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    // Sort tất cả theo ngày tăng dần
    final allTrips = [...vm.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Đảm bảo index không vượt quá độ dài list
    if (_selectedIndex >= allTrips.length && allTrips.isNotEmpty) {
      _selectedIndex = 0;
    }

    final selectedTrip = allTrips.isNotEmpty ? allTrips[_selectedIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Sổ tay Lịch trình',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brownDeep,
                    ),
                  ),
                  const Spacer(),
                  _CircleBtn(
                    icon: Icons.refresh_rounded,
                    color: AppColors.primary,
                    onTap: () => vm.loadTrips(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Date Chips — 1 chip = 1 ngày ─────────────────────────
            if (allTrips.isNotEmpty)
              SizedBox(
                height: 92,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  itemCount: allTrips.length,
                  itemBuilder: (_, i) {
                    final t = allTrips[i];
                    final isSelected = i == _selectedIndex;
                    final isPast = t.isPast && !t.isToday;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isPast
                              ? Colors.grey.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade200),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Nhãn âm lịch M.1, M.2... hoặc ngày/tháng
                            Text(
                              t.shortDateLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: t.shortDateLabel.length > 3 ? 13 : 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : isPast
                                    ? Colors.grey.shade400
                                    : AppColors.brownDeep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Ngày dương lịch
                            Text(
                              '${t.startDate.day}/${t.startDate.month}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.75)
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Badge số hoạt động
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : isPast
                                    ? Colors.grey.shade200
                                    : AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${t.activities.length} h.động',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : isPast
                                      ? Colors.grey.shade400
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // ── Chi tiết ngày được chọn ───────────────────────────────
            Expanded(
              child: vm.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : allTrips.isEmpty
                  ? _EmptyState(
                      onAdd: () async {
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTripScreen(),
                          ),
                        );
                        if (ok == true) vm.loadTrips();
                      },
                    )
                  : _DayDetailView(
                      trip: selectedTrip!,
                      onDelete: () => _confirmDelete(context, vm, selectedTrip),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chi tiết 1 ngày ───────────────────────────────────────────────────────────
class _DayDetailView extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDelete;

  const _DayDetailView({required this.trip, required this.onDelete});

  String _fmtDate(DateTime d) {
    const w = [
      'Chủ nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ];
    return '${w[d.weekday % 7]}, ${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPast = trip.isPast && !trip.isToday;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề ngày ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPast ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPast
                    ? Colors.grey.shade200
                    : AppColors.primary.withOpacity(0.15),
              ),
              boxShadow: isPast
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? Colors.grey.shade200
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              trip.shortDateLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isPast
                                    ? Colors.grey.shade500
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          if (trip.isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'HÔM NAY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trip.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isPast
                              ? Colors.grey.shade500
                              : AppColors.brownDeep,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(trip.startDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nút xoá
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade300,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Timeline hoạt động ───────────────────────────────────
          if (trip.activities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    color: Colors.grey.shade400,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ngày này chưa có hoạt động',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Stack(
              children: [
                // Đường kẻ dọc timeline
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: isPast
                        ? Colors.grey.shade200
                        : AppColors.primary.withOpacity(0.15),
                  ),
                ),
                Column(
                  children: trip.activities.asMap().entries.map((e) {
                    final i = e.key;
                    final act = e.value;
                    final isFirst = i == 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dot
                          Container(
                            width: 42,
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.only(top: 14),
                            child: Container(
                              width: isFirst ? 14 : 10,
                              height: isFirst ? 14 : 10,
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey.shade300
                                    : isFirst
                                    ? AppColors.primary
                                    : AppColors.primary.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.warmCream,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // Card hoạt động
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.white.withOpacity(0.55)
                                    : isFirst
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isFirst && !isPast
                                      ? AppColors.primary.withOpacity(0.2)
                                      : Colors.grey.shade100,
                                ),
                                boxShadow: isFirst && !isPast
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Badge giờ
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPast
                                          ? Colors.grey.shade100
                                          : AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${act.hour.toString().padLeft(2, '0')}:${act.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isPast
                                            ? Colors.grey.shade400
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Tên + địa điểm
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isPast
                                                ? Colors.grey.shade500
                                                : AppColors.brownDeep,
                                          ),
                                        ),
                                        if (act.location.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 12,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  act.location,
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.brownDeep),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch trình nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.brownDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo kế hoạch đầu tiên!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.brownMid,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Tạo kế hoạch',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
