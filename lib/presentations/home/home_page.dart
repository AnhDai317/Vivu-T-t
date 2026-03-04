import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';
import 'package:vivu_tet/presentations/home/home_header.dart';
import 'package:vivu_tet/presentations/home/home_menu_button.dart';
import 'package:vivu_tet/presentations/planner/trip_list_screen.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: const HomeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(),
            const SizedBox(height: 24),
            const HomeMenuButtons(),
            const SizedBox(height: 32),
            const _TripsSection(),
            const SizedBox(height: 28),
            const _GardenSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.festiveGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ĐẾM NGƯỢC',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(text: 'Còn '),
                          TextSpan(
                            text: '15',
                            style: TextStyle(color: AppColors.gold),
                          ),
                          TextSpan(text: ' ngày'),
                        ],
                      ),
                    ),
                    Text(
                      'Đến Tết Nguyên Đán',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_queue_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HÀ NỘI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '18°C',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Se lạnh • Có mưa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chạm để xem chi tiết thời tiết Tết',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trips Section ─────────────────────────────────────────────────────────────
class _TripsSection extends StatelessWidget {
  const _TripsSection();

  // Helper push TripListScreen kèm vm
  void _goToTripList(BuildContext context) {
    final vm = context.read<HomeViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: const TripListScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    final upcomingTrips = vm.trips.where((t) => !t.isPast || t.isToday).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final displayTrips = upcomingTrips.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_note,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kế hoạch của bạn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brownDeep,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _goToTripList(context),
                child: Text(
                  'TẤT CẢ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (vm.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (vm.trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.luggage_rounded,
                    color: Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có kế hoạch nào',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bấm + để tạo chuyến đi đầu tiên!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
              ),
              child: Column(
                children: displayTrips
                    .asMap()
                    .entries
                    .map(
                      (e) =>
                          _TripTimelineItem(trip: e.value, isFirst: e.key == 0),
                    )
                    .toList(),
              ),
            ),
          ),
          if (upcomingTrips.length > 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: GestureDetector(
                onTap: () => _goToTripList(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    'Xem thêm ${upcomingTrips.length - 2} kế hoạch →',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TripTimelineItem extends StatelessWidget {
  final Trip trip;
  final bool isFirst;
  const _TripTimelineItem({required this.trip, required this.isFirst});

  String _formatDate(DateTime d) {
    const weekdays = [
      'CN',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
    ];
    return '${weekdays[d.weekday % 7]}, ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst ? AppColors.primary : Colors.grey.shade400;

    return Stack(
      children: [
        Positioned(
          left: -6,
          top: 10,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warmCream, width: 2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFirst ? Colors.white : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDate(trip.startDate).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isFirst
                              ? AppColors.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      '${trip.activities.length} h.động',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  trip.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDeep,
                  ),
                ),
                if (trip.activities.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${trip.activities.first.hour.toString().padLeft(2, '0')}:${trip.activities.first.minute.toString().padLeft(2, '0')} • ${trip.activities.first.title}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trip.activities.length > 1)
                        Text(
                          '+${trip.activities.length - 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Garden Section ────────────────────────────────────────────────────────────
class _GardenSection extends StatelessWidget {
  const _GardenSection();

  static const _gardens = [
    _GardenItem(
      tag: 'Hot',
      location: 'Nhật Tân, Hà Nội',
      name: 'Thung Lũng Hoa Đào',
      desc: 'Sắc xuân rực rỡ với hàng nghìn gốc đào cổ.',
    ),
    _GardenItem(
      tag: 'Mới',
      location: 'Văn Giang, Hưng Yên',
      name: 'Vườn Quất Di Sản',
      desc: 'Không gian nghệ thuật cây cảnh truyền thống.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Gợi ý điểm du xuân',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.brownDeep,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _gardens.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: i < _gardens.length - 1 ? 12 : 0),
              child: _GardenCard(item: _gardens[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _GardenItem {
  final String tag, location, name, desc;
  const _GardenItem({
    required this.tag,
    required this.location,
    required this.name,
    required this.desc,
  });
}

class _GardenCard extends StatelessWidget {
  const _GardenCard({required this.item});
  final _GardenItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 90,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '4.8★',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDeep,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      color: Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '12km • Hà Nội',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
