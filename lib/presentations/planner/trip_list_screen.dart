// LƯU Ý: Đây là phần THAY THẾ / BỔ SUNG vào trip_list_screen.dart hiện có.
// Các phần không đề cập giữ nguyên như cũ.
//
// THAY ĐỔI CHÍNH:
//   1. _DayDetailView → activities dùng ReorderableListView thay ListView
//   2. Thêm nút "Mở tất cả điểm trên Google Maps" (waypoints)
//   3. HomeViewModel cần thêm reorderActivity() — xem home_viewmodel_patch.dart
//
// ── IMPORT cần thêm (nếu chưa có) ────────────────────────────────────────────
//   import 'package:url_launcher/url_launcher.dart'; // đã có sẵn

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vivu_tet/data/implementations/api/weather_api.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/domain/entities/trip_activity.dart';
import 'package:vivu_tet/domain/entities/weather.dart';
import 'package:vivu_tet/presentations/checklist/checklist_screen.dart';
import 'package:vivu_tet/presentations/planner/create_trip_screen.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';
import 'package:vivu_tet/presentations/planner/trip_story_exporter.dart';

class TripListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const TripListScreen({super.key, this.onBack});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  int _selectedIndex = 0;
  final _shareKey = GlobalKey();

  final Map<String, Weather?> _forecastCache = {};
  final _weatherApi = WeatherApi();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _autoSelectNearestDate(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<HomeViewModel>();
    if (vm.selectedTripDate != null) {
      _jumpToDate(vm.selectedTripDate!);
      vm.clearSelectedTripDate();
    }
  }

  void _jumpToDate(DateTime targetDate) {
    final vm = context.read<HomeViewModel>();
    final allTrips = [...vm.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (allTrips.isEmpty) return;
    final idx = allTrips.indexWhere(
      (t) =>
          t.startDate.year == targetDate.year &&
          t.startDate.month == targetDate.month &&
          t.startDate.day == targetDate.day,
    );
    if (idx >= 0 && mounted) setState(() => _selectedIndex = idx);
  }

  void _autoSelectNearestDate() {
    final vm = context.read<HomeViewModel>();
    if (vm.selectedTripDate != null) {
      _jumpToDate(vm.selectedTripDate!);
      vm.clearSelectedTripDate();
      return;
    }
    final allTrips = [...vm.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (allTrips.isEmpty) return;
    final today = DateTime.now();
    int idx = allTrips.indexWhere(
      (t) =>
          t.startDate.year == today.year &&
          t.startDate.month == today.month &&
          t.startDate.day == today.day,
    );
    if (idx < 0) idx = allTrips.indexWhere((t) => !t.isPast || t.isToday);
    if (idx < 0 && allTrips.isNotEmpty) idx = allTrips.length - 1;
    if (idx >= 0 && mounted) setState(() => _selectedIndex = idx);
  }

  Future<void> _openMapsForLocation(String location) async {
    if (location.trim().isEmpty) return;
    final q = Uri.encodeComponent(location.trim());
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

  void _openPackingList(Trip trip) {
    final checklistVm = context.read<ChecklistViewModel>();
    checklistVm.selectDate(trip.startDate);
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

  Future<void> _loadForecast(Trip trip) async {
    if (_forecastCache.containsKey(trip.id)) return;
    final w = await _weatherApi.getForecastForDate(trip.startDate);
    if (mounted) setState(() => _forecastCache[trip.id] = w);
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _showEditTitleDialog(BuildContext ctx, HomeViewModel vm, Trip trip) {
    final ctrl = TextEditingController(text: trip.title);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sửa tên kế hoạch',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tên kế hoạch...',
            filled: true,
            fillColor: AppColors.warmCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppColors.brownDeep,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'HỦY',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx);
              await vm.updateTripTitle(tripId: trip.id, newTitle: t);
            },
            child: Text(
              'LƯU',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditActivityDialog(
    BuildContext ctx,
    HomeViewModel vm,
    Trip trip,
    TripActivity act,
  ) {
    TimeOfDay selectedTime = TimeOfDay(hour: act.hour, minute: act.minute);
    final titleCtrl = TextEditingController(text: act.title);
    final locationCtrl = TextEditingController(text: act.location);

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sửa hoạt động',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Thời gian: ${selectedTime.format(c)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: c,
                      initialTime: selectedTime,
                    );
                    if (t != null) setS(() => selectedTime = t);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tên hoạt động',
                    filled: true,
                    fillColor: AppColors.warmCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    hintText: 'Địa điểm (tuỳ chọn)',
                    filled: true,
                    fillColor: AppColors.warmCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(c);
                await vm.updateActivity(
                  tripId: trip.id,
                  activityId: act.id,
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                  title: titleCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                );
              },
              child: Text(
                'LƯU',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteActivity(
    BuildContext ctx,
    HomeViewModel vm,
    Trip trip,
    TripActivity act,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xoá hoạt động?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDeep,
          ),
        ),
        content: Text(
          '"${act.title}"',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.brownMid,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Huỷ',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteActivity(tripId: trip.id, activityId: act.id);
            },
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

  void _shareAsText(Trip trip) {
    final buf = StringBuffer();
    buf.writeln('🌸 Lịch trình Du Xuân — ${trip.title} 🌸');
    buf.writeln(
      '📅 ${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year}',
    );
    buf.writeln('');
    if (trip.activities.isEmpty) {
      buf.writeln('(Chưa có hoạt động nào)');
    } else {
      for (final act in trip.activities) {
        final h = act.hour.toString().padLeft(2, '0');
        final m = act.minute.toString().padLeft(2, '0');
        buf.writeln('🕐 $h:$m  ${act.title}');
        if (act.location.isNotEmpty) buf.writeln('   📍 ${act.location}');
      }
    }
    buf.writeln('');
    buf.writeln('📱 Tạo bởi ViVu Tết 2027 🎋');
    Share.share(buf.toString(), subject: 'Kế hoạch: ${trip.title}');
  }

  Future<void> _shareAsImage(Trip trip) async {
    try {
      final boundary =
          _shareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/plan_${trip.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '🌸 ${trip.title} — ViVu Tết 2027');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất ảnh: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _copyToClipboard(Trip trip) {
    final buf = StringBuffer();
    buf.writeln('🌸 ${trip.title}');
    buf.writeln(
      '📅 ${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year}',
    );
    for (final act in trip.activities) {
      final h = act.hour.toString().padLeft(2, '0');
      final m = act.minute.toString().padLeft(2, '0');
      buf.writeln('🕐 $h:$m  ${act.title}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã copy kế hoạch!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showShareSheet(Trip trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chia sẻ kế hoạch',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.brownDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trip.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            // MỚI: Story card
            _ShareOptionHighlight(
              icon: Icons.auto_awesome_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              label: '✨ Xuất ảnh Story Tết',
              subtitle: 'Card đẹp cho Facebook/Zalo Story',
              onTap: () {
                Navigator.pop(context);
                showStoryExporter(context: context, trip: trip);
              },
            ),
            const SizedBox(height: 10),
            _ShareOption(
              icon: Icons.share_rounded,
              color: const Color(0xFF4FACFE),
              label: 'Chia sẻ dạng văn bản',
              subtitle: 'Gửi qua Zalo, Messenger, SMS...',
              onTap: () {
                Navigator.pop(context);
                _shareAsText(trip);
              },
            ),
            const SizedBox(height: 10),
            _ShareOption(
              icon: Icons.copy_rounded,
              color: const Color(0xFF43E97B),
              label: 'Copy vào clipboard',
              subtitle: 'Dán vào bất cứ đâu',
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(trip);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTrip(HomeViewModel vm, Trip trip) {
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
    final allTrips = [...vm.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (_selectedIndex >= allTrips.length && allTrips.isNotEmpty) {
      _selectedIndex = 0;
    }

    final selectedTrip = allTrips.isNotEmpty ? allTrips[_selectedIndex] : null;

    if (selectedTrip != null) {
      _loadForecast(selectedTrip);
    }

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _handleBack,
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
                  if (selectedTrip != null)
                    _CircleBtn(
                      icon: Icons.ios_share_rounded,
                      color: AppColors.primary,
                      onTap: () => _showShareSheet(selectedTrip),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Date Chips ──────────────────────────────────────────
            if (allTrips.isNotEmpty)
              SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            Text(
                              t.shortDateLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: t.shortDateLabel.length > 3 ? 12 : 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : isPast
                                    ? Colors.grey.shade400
                                    : AppColors.brownDeep,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
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
                        if (ok == true && mounted) vm.loadTrips();
                      },
                    )
                  : RepaintBoundary(
                      key: _shareKey,
                      child: _DayDetailView(
                        trip: selectedTrip!,
                        forecast: _forecastCache[selectedTrip.id],
                        onDeleteTrip: () =>
                            _confirmDeleteTrip(vm, selectedTrip),
                        onEditTitle: () =>
                            _showEditTitleDialog(context, vm, selectedTrip),
                        onEditActivity: (act) => _showEditActivityDialog(
                          context,
                          vm,
                          selectedTrip,
                          act,
                        ),
                        onDeleteActivity: (act) => _confirmDeleteActivity(
                          context,
                          vm,
                          selectedTrip,
                          act,
                        ),
                        onOpenMaps: (location) =>
                            _openMapsForLocation(location),
                        onPackingList: () => _openPackingList(selectedTrip),
                        // MỚI: callback reorder
                        onReorderActivities: (oldIndex, newIndex) =>
                            vm.reorderActivity(
                              tripId: selectedTrip.id,
                              oldIndex: oldIndex,
                              newIndex: newIndex,
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

// ── Day Detail View ────────────────────────────────────────────────────────────
class _DayDetailView extends StatelessWidget {
  final Trip trip;
  final Weather? forecast;
  final VoidCallback onDeleteTrip;
  final VoidCallback onEditTitle;
  final void Function(TripActivity) onEditActivity;
  final void Function(TripActivity) onDeleteActivity;
  final void Function(String location) onOpenMaps;
  final VoidCallback onPackingList;
  final void Function(int oldIndex, int newIndex) onReorderActivities; // MỚI

  const _DayDetailView({
    required this.trip,
    required this.forecast,
    required this.onDeleteTrip,
    required this.onEditTitle,
    required this.onEditActivity,
    required this.onDeleteActivity,
    required this.onOpenMaps,
    required this.onPackingList,
    required this.onReorderActivities,
  });

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
          // ── Trip header card ─────────────────────────────────────
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
                          if (forecast != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    forecast!.icon,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    forecast!.maxTemp != null
                                        ? '${forecast!.minTemp!.toStringAsFixed(0)}–${forecast!.maxTemp!.toStringAsFixed(0)}°C'
                                        : '${forecast!.temperature.toStringAsFixed(0)}°C',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trip.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isPast
                                    ? Colors.grey.shade500
                                    : AppColors.brownDeep,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onEditTitle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey.shade200
                                    : AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 13,
                                    color: isPast
                                        ? Colors.grey.shade400
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Sửa tên',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isPast
                                          ? Colors.grey.shade400
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(trip.startDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      // Cảnh báo thời tiết xấu
                      if (forecast != null &&
                          (forecast!.description.contains('Mưa') ||
                              forecast!.description.contains('Dông') ||
                              forecast!.description.contains('Sương'))) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('⚠️', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${forecast!.description} — Nhớ mang ô/áo mưa nhé!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDeleteTrip,
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

          // ── Activities section header ────────────────────────────
          if (trip.activities.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Lịch trình chi tiết',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brownMid,
                  ),
                ),
                const SizedBox(width: 8),
                // Hint kéo thả
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.drag_indicator_rounded,
                        size: 12,
                        color: AppColors.primary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Giữ để sắp xếp',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── MỚI: ReorderableListView thay cho ListView tĩnh ─────
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
            // ReorderableListView.builder — kéo thả native Flutter
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Padding bottom để không bị che bởi nội dung bên dưới
              padding: EdgeInsets.zero,
              itemCount: trip.activities.length,
              onReorder: onReorderActivities,
              // Tuỳ chỉnh proxy decoration khi đang kéo
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    shadowColor: AppColors.primary.withOpacity(0.3),
                    color: Colors.transparent,
                    child: child,
                  ),
                );
              },
              itemBuilder: (_, index) {
                final act = trip.activities[index];
                // Key bắt buộc cho ReorderableListView
                return _ActivityCard(
                  key: ValueKey(act.id),
                  activity: act,
                  isPast: isPast,
                  onEdit: () => onEditActivity(act),
                  onDelete: () => onDeleteActivity(act),
                  onOpenMaps: act.location.isNotEmpty
                      ? () => onOpenMaps(act.location)
                      : null,
                );
              },
            ),

          const SizedBox(height: 16),

          // ── CTA: Chuẩn bị hành trang ────────────────────────────
          GestureDetector(
            onTap: onPackingList,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF43A047).withOpacity(0.08),
                    const Color(0xFF43A047).withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF43A047).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: Color(0xFF43A047),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuẩn bị hành trang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brownDeep,
                          ),
                        ),
                        Text(
                          'Mở Checklist ngày ${trip.startDate.day}/${trip.startDate.month}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF43A047),
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

// ── Activity Card — tách riêng để ReorderableListView hoạt động tốt ──────────
class _ActivityCard extends StatelessWidget {
  final TripActivity activity;
  final bool isPast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenMaps;

  const _ActivityCard({
    super.key,
    required this.activity,
    required this.isPast,
    required this.onEdit,
    required this.onDelete,
    this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    final act = activity;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: isPast ? Colors.white.withOpacity(0.55) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPast
              ? Colors.grey.shade100
              : AppColors.primary.withOpacity(0.12),
        ),
        boxShadow: isPast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 20,
              color: isPast
                  ? Colors.grey.shade300
                  : AppColors.primary.withOpacity(0.35),
            ),
          ),

          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                color: isPast ? Colors.grey.shade400 : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPast ? Colors.grey.shade500 : AppColors.brownDeep,
                  ),
                ),
                if (act.location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: onOpenMaps,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            act.location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.primary.withOpacity(0.8),
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary.withOpacity(
                                0.4,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Nút sửa
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.grey.shade100
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 14,
                color: isPast ? Colors.grey.shade400 : AppColors.primary,
              ),
            ),
          ),

          // Nút xoá
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 14,
                color: Colors.red.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets (giữ nguyên từ file cũ) ─────────────────────────────────
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _ShareOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brownDeep,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
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

// ── Share option highlight (Story export) ────────────────────────────────────
class _ShareOptionHighlight extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionHighlight({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB71C1C).withOpacity(0.08),
              const Color(0xFFFFD700).withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB71C1C).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brownDeep,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'MỚI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB71C1C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
