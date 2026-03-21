import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vivu_tet/data/static/spring_destinations_data.dart';
import 'package:vivu_tet/domain/entities/spring_destination.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';

class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  String _selectedCategory = 'all';

  static const _cats = [
    ('all', '🗺️', 'Tất cả'),
    ('flower', '🌸', 'Vườn hoa'),
    ('temple', '🛕', 'Chùa'),
    ('festival', '🎊', 'Lễ hội'),
    ('heritage', '🏛️', 'Di tích'),
  ];

  List<SpringDestination> get _filtered => _selectedCategory == 'all'
      ? SpringDestinationsData.all
      : SpringDestinationsData.all
            .where((d) => d.category == _selectedCategory)
            .toList();

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

  void _showAddToTripSheet(BuildContext context, SpringDestination dest) {
    // FIX: Đọc vm từ context hiện tại (đã được provide bởi home_page)
    final vm = context.read<HomeViewModel>();
    final trips = [...vm.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chưa có lịch trình nào. Hãy tạo lịch trình trước!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // FIX: isScrollControlled = true để bottom sheet mở rộng khi bàn phím lên
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        // FIX: Re-provide vm vào trong bottom sheet builder context
        value: vm,
        child: _AddToTripSheet(dest: dest, trips: trips),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.brownDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GỢI Ý DU XUÂN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Điểm đến Tết 2027',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brownDeep,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length} địa điểm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Category filter ──────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final cat = _cats[i];
                  final isActive = cat.$1 == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isActive
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${cat.$2} ${cat.$3}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final dest = filtered[i];
                  return _DestCard(
                    dest: dest,
                    onDirections: () => _openMaps(dest),
                    onAddToTrip: () => _showAddToTripSheet(context, dest),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet — FIX overflow ────────────────────────────────────────────────
class _AddToTripSheet extends StatefulWidget {
  final SpringDestination dest;
  final List<Trip> trips;

  const _AddToTripSheet({required this.dest, required this.trips});

  @override
  State<_AddToTripSheet> createState() => _AddToTripSheetState();
}

class _AddToTripSheetState extends State<_AddToTripSheet> {
  Trip? _selectedTrip;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = false;

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HomeViewModel>();
    // FIX: Dùng DraggableScrollableSheet để tránh overflow hoàn toàn
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
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

            // Tiêu đề
            Row(
              children: [
                Text(widget.dest.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thêm vào lịch trình',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brownDeep,
                        ),
                      ),
                      Text(
                        widget.dest.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.brownMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Chọn ngày
            Text(
              'Chọn ngày:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.trips.length,
                itemBuilder: (_, i) {
                  final t = widget.trips[i];
                  final isSelected = _selectedTrip?.id == t.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTrip = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.brownDeep,
                            ),
                          ),
                          Text(
                            _fmtDate(t.startDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Chọn giờ
            Text(
              'Chọn giờ:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        onSurface: AppColors.brownDeep,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => _selectedTime = t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDeep,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Chọn giờ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nút Thêm
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTrip == null || _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await vm.addActivityFromDestination(
                          tripId: _selectedTrip!.id,
                          activityTitle: widget.dest.name,
                          location: widget.dest.location,
                          hour: _selectedTime.hour,
                          minute: _selectedTime.minute,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã thêm "${widget.dest.name}" vào lịch trình! 🎉',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedTrip == null
                            ? 'Chọn ngày trước'
                            : 'Thêm vào lịch trình',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

// ── Dest Card ─────────────────────────────────────────────────────────────────
class _DestCard extends StatelessWidget {
  final SpringDestination dest;
  final VoidCallback onDirections;
  final VoidCallback onAddToTrip;

  const _DestCard({
    required this.dest,
    required this.onDirections,
    required this.onAddToTrip,
  });

  Color get _catColor {
    switch (dest.category) {
      case 'flower':
        return const Color(0xFFE91E8C);
      case 'temple':
        return const Color(0xFFF57C00);
      case 'festival':
        return const Color(0xFF7B1FA2);
      case 'heritage':
        return const Color(0xFF00897B);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 100,
              height: 110,
              child: _DestImage(dest: dest, catColor: _catColor),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dest.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brownDeep,
                          ),
                        ),
                      ),
                      if (dest.isHot)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🔥 Hot',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                          dest.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        '${dest.rating}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const Spacer(),
                      // Nút + Thêm vào lịch trình
                      GestureDetector(
                        onTap: onAddToTrip,
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      // Nút chỉ đường
                      GestureDetector(
                        onTap: onDirections,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
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

class _DestImage extends StatelessWidget {
  final SpringDestination dest;
  final Color catColor;
  const _DestImage({required this.dest, required this.catColor});

  @override
  Widget build(BuildContext context) {
    if (dest.imagePath.isEmpty) return _fallback();
    return Image.asset(
      dest.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(
    color: catColor.withOpacity(0.1),
    child: Center(
      child: Text(dest.emoji, style: const TextStyle(fontSize: 32)),
    ),
  );
}
