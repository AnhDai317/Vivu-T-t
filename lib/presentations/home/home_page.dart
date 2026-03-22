import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vivu_tet/data/implementations/api/weather_api.dart';
import 'package:vivu_tet/data/static/spring_destinations_data.dart';
import 'package:vivu_tet/domain/entities/spring_destination.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/domain/entities/weather.dart';
import 'package:vivu_tet/main_screen.dart';
import 'package:vivu_tet/presentations/destinations/destinations_screen.dart';
import 'package:vivu_tet/presentations/map/map_screen.dart';
import 'package:vivu_tet/presentations/checklist/checklist_screen.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/utils/tet_date_utils.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Weather? _weather;
  bool _weatherLoading = true;
  bool _reminderDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _weatherLoading = true);
    try {
      final w = await WeatherApi().getCurrentWeather();
      if (mounted) setState(() => _weather = w);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  MainScreenState? get _mainState =>
      context.findAncestorStateOfType<MainScreenState>();

  void _goToTripList({DateTime? selectDate}) =>
      _mainState?.openTripList(selectDate: selectDate);

  void _goToMap() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MapScreen()),
  );

  void _goToChecklist() {
    final checklistVm = context.read<ChecklistViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: checklistVm,
          child: const ChecklistScreen(),
        ),
      ),
    );
  }

  void _goToDestinations() {
    final homeVm = context.read<HomeViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: homeVm,
          child: const DestinationsScreen(),
        ),
      ),
    );
  }

  Future<void> _openMaps(SpringDestination dest) async {
    final q = Uri.encodeComponent(dest.name);
    final gmapsApp = Uri.parse('google.navigation:q=$q&mode=d');
    final gmapsWeb = Uri.parse('https://www.google.com/maps/search/$q');
    try {
      if (await canLaunchUrl(gmapsApp)) {
        await launchUrl(gmapsApp);
      } else {
        await launchUrl(gmapsWeb, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ── FIX: Chỉ lấy reminder trong ngày HÔM NAY ──────────────────────────────
  List<String> _getUpcomingReminders(HomeViewModel vm) {
    final reminders = <String>[];
    final now = DateTime.now();

    // FIX: Chỉ đến cuối hôm nay, không lấy ngày mai
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    for (final trip in vm.trips) {
      // Chỉ xét trip của HÔM NAY
      final isToday =
          trip.startDate.year == now.year &&
          trip.startDate.month == now.month &&
          trip.startDate.day == now.day;
      if (!isToday) continue;

      for (final act in trip.activities) {
        final actTime = DateTime(
          trip.startDate.year,
          trip.startDate.month,
          trip.startDate.day,
          act.hour,
          act.minute,
        );
        // Chỉ lấy các activity sau giờ hiện tại và trong hôm nay
        if (actTime.isAfter(now) && actTime.isBefore(todayEnd)) {
          final h = act.hour.toString().padLeft(2, '0');
          final m = act.minute.toString().padLeft(2, '0');
          reminders.add('$h:$m — ${act.title}');
        }
      }
    }
    return reminders;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final vm = context.watch<HomeViewModel>();
    final reminders = _getUpcomingReminders(vm);
    final tetInfo = TetDateUtils.nextTet();
    final daysLeft = TetDateUtils.daysUntilNextTet();
    final lunarYear = tetInfo.lunarYear;
    final canChi = TetDateUtils.canChiOfYear(lunarYear);
    final emoji = TetDateUtils.emojiOfYear(lunarYear) ?? '🎋';

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào! 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'ViVu Tết $lunarYear',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brownDeep,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: reminders.isEmpty
                            ? null
                            : () => _showReminderSheet(reminders),
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                reminders.isEmpty
                                    ? Icons.notifications_outlined
                                    : Icons.notifications_active_rounded,
                                color: reminders.isEmpty
                                    ? AppColors.brownDeep
                                    : AppColors.primary,
                                size: 22,
                              ),
                            ),
                            if (reminders.isNotEmpty)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Reminder banner ───────────────────────────────────────
                if (reminders.isNotEmpty && !_reminderDismissed)
                  _ReminderBanner(
                    count: reminders.length,
                    firstItem: reminders.first,
                    onTap: () => _showReminderSheet(reminders),
                    onDismiss: () => setState(() => _reminderDismissed = true),
                  ),

                const SizedBox(height: 16),

                // ── Hero banner ───────────────────────────────────────────
                _HeroBanner(
                  daysLeft: daysLeft,
                  lunarYear: lunarYear,
                  canChi: canChi,
                  tetEmoji: emoji,
                  weather: _weather,
                  weatherLoading: _weatherLoading,
                ),

                const SizedBox(height: 20),

                // ── Menu buttons ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MenuBtn(
                        icon: Icons.menu_book_rounded,
                        line1: 'Sổ tay',
                        line2: 'Lịch trình',
                        color: const Color(0xFFE53935),
                        onTap: () => _goToTripList(),
                      ),
                      _MenuBtn(
                        icon: Icons.map_rounded,
                        line1: 'Bản đồ',
                        line2: 'Du xuân',
                        color: const Color(0xFF1E88E5),
                        onTap: _goToMap,
                      ),
                      _MenuBtn(
                        icon: Icons.checklist_rounded,
                        line1: 'Checklist',
                        line2: 'Hành trang',
                        color: const Color(0xFF43A047),
                        onTap: _goToChecklist,
                      ),
                      _MenuBtn(
                        icon: Icons.place_rounded,
                        line1: 'Gợi ý',
                        line2: 'Điểm đến',
                        color: const Color(0xFF8E24AA),
                        onTap: _goToDestinations,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _TripsSection(
                  onViewAll: () => _goToTripList(),
                  onTapCard: (date) => _goToTripList(selectDate: date),
                ),

                const SizedBox(height: 28),

                _DestinationsSection(
                  onViewAll: _goToDestinations,
                  onOpenMaps: _openMaps,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FIX: Reminder sheet — SingleChildScrollView để không overflow ──────────
  void _showReminderSheet(List<String> reminders) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // FIX: isScrollControlled để sheet không bị giới hạn chiều cao
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        // FIX: SafeArea bao ngoài để tránh notch/navbar
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            // FIX: mainAxisSize.min để sheet tự co theo nội dung
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Sắp diễn ra hôm nay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brownDeep,
                    ),
                  ),
                  const Spacer(),
                  // FIX: Nút đóng rõ ràng
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // FIX: Giới hạn chiều cao list, scroll nếu nhiều item
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: reminders
                        .map(
                          (r) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brownDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reminder Banner ────────────────────────────────────────────────────────────
class _ReminderBanner extends StatelessWidget {
  final int count;
  final String firstItem;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ReminderBanner({
    required this.count,
    required this.firstItem,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1
                        ? 'Có 1 hoạt động sắp diễn ra'
                        : 'Có $count hoạt động sắp diễn ra hôm nay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    firstItem,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.brownMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final int daysLeft;
  final int lunarYear;
  final String canChi;
  final String tetEmoji;
  final Weather? weather;
  final bool weatherLoading;

  const _HeroBanner({
    required this.daysLeft,
    required this.lunarYear,
    required this.canChi,
    required this.tetEmoji,
    required this.weather,
    required this.weatherLoading,
  });

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
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
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
                      Text(tetEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        'ĐẾM NGƯỢC TẾT $lunarYear',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '$daysLeft',
                          style: const TextStyle(color: Color(0xFFFFD54F)),
                        ),
                        const TextSpan(text: ' ngày'),
                      ],
                    ),
                  ),
                  Text(
                    'đến Tết $canChi $lunarYear',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.white.withOpacity(0.25),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: weatherLoading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Đang tải...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  : weather == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('🌡️', style: TextStyle(fontSize: 26)),
                        Text(
                          'Không có\ndữ liệu',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                weather!.cityName.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              weather!.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${weather!.temperature.toStringAsFixed(0)}°C',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          weather!.description,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu Button ────────────────────────────────────────────────────────────────
class _MenuBtn extends StatefulWidget {
  final IconData icon;
  final String line1, line2;
  final Color color;
  final VoidCallback onTap;

  const _MenuBtn({
    required this.icon,
    required this.line1,
    required this.line2,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuBtn> createState() => _MenuBtnState();
}

class _MenuBtnState extends State<_MenuBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.92,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(widget.icon, color: widget.color, size: 30),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.line1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.brownDeep,
              ),
            ),
            Text(
              widget.line2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trips Section ──────────────────────────────────────────────────────────────
class _TripsSection extends StatelessWidget {
  final VoidCallback onViewAll;
  final ValueChanged<DateTime> onTapCard;

  const _TripsSection({required this.onViewAll, required this.onTapCard});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final upcoming = vm.trips.where((t) => !t.isPast || t.isToday).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final displayDays = upcoming.take(2).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 Kế hoạch sắp tới',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brownDeep,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (vm.isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else if (vm.trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có kế hoạch nào',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey.shade600,
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
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: displayDays
                  .map(
                    (t) =>
                        _TripCard(trip: t, onTap: () => onTapCard(t.startDate)),
                  )
                  .toList(),
            ),
          ),
          if (upcoming.length > 2) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: onViewAll,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Xem thêm ${upcoming.length - 2} ngày →',
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
      ],
    );
  }
}

// ── Trip Card ──────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final previewActs = trip.activities.take(2).toList();
    final extraCount = trip.activities.length - 2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trip.shortDateLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trip.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDeep,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trip.isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
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
              ),
            ),
            if (trip.activities.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Chưa có hoạt động',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Divider(height: 1, color: Colors.grey.shade100),
              ...previewActs.map(
                (act) => Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${act.hour.toString().padLeft(2, '0')}:${act.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          act.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brownDeep,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (extraCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Text(
                    '+$extraCount hoạt động nữa...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Destinations Section ───────────────────────────────────────────────────────
class _DestinationsSection extends StatelessWidget {
  final VoidCallback onViewAll;
  final Function(SpringDestination) onOpenMaps;

  const _DestinationsSection({
    required this.onViewAll,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    final featured = SpringDestinationsData.featured;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🌸 Gợi ý du xuân',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brownDeep,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            itemBuilder: (_, i) {
              final dest = featured[i];
              return GestureDetector(
                onTap: () => onOpenMaps(dest),
                child: Container(
                  width: 160,
                  margin: EdgeInsets.only(
                    right: i < featured.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        dest.imagePath.isNotEmpty
                            ? Image.asset(
                                dest.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imgFallback(dest),
                              )
                            : _imgFallback(dest),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.68),
                              ],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        ),
                        if (dest.isHot)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '🔥 Hot',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dest.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 11,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${dest.rating}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.navigation_rounded,
                                      color: Colors.white,
                                      size: 13,
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _imgFallback(SpringDestination dest) => Container(
    color: AppColors.primary.withOpacity(0.12),
    child: Center(
      child: Text(dest.emoji, style: const TextStyle(fontSize: 44)),
    ),
  );
}
