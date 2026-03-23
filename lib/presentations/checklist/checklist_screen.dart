import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/data/implementations/api/weather_api.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';
import 'package:vivu_tet/domain/entities/trip.dart';
import 'package:vivu_tet/domain/entities/weather.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/presentations/shared/widgets/smart_suggestion_sheet.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCat = 0;
  Weather? _weather;
  bool _weatherLoading = false;
  final _weatherApi = WeatherApi();

  @override
  void initState() {
    super.initState();
    // Load weather theo ngày mặc định (hôm nay)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChecklistViewModel>();
      _loadWeather(vm.selectedDate);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChecklistViewModel>();
      if (vm.categories.isEmpty && !vm.isLoading) {
        vm.loadCategories();
      }
    });
  }

  Future<void> _loadWeather(DateTime date) async {
    setState(() {
      _weatherLoading = true;
      _weather = null; // reset khi đổi ngày
    });
    try {
      final now = DateTime.now();
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      Weather? w;
      if (isToday) {
        // Hôm nay: lấy thời tiết hiện tại
        w = await _weatherApi.getCurrentWeather();
      } else {
        // Ngày khác: lấy forecast của ngày đó
        w = await _weatherApi.getForecastForDate(date);
      }
      if (mounted) setState(() => _weather = w);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  // ── Smart suggestion ────────────────────────────────────────────────────
  void _showSmartSuggestions(ChecklistViewModel vm) {
    Trip trip;
    try {
      final homeVm = context.read<HomeViewModel>();
      final d = vm.selectedDate;
      final found = homeVm.trips
          .where(
            (t) =>
                t.startDate.year == d.year &&
                t.startDate.month == d.month &&
                t.startDate.day == d.day,
          )
          .toList();
      trip = found.isNotEmpty
          ? found.first
          : Trip(
              id: 'tmp',
              title: 'Ngày ${d.day}/${d.month}',
              startDate: d,
              endDate: d,
            );
    } catch (_) {
      final d = vm.selectedDate;
      trip = Trip(
        id: 'tmp',
        title: 'Ngày ${d.day}/${d.month}',
        startDate: d,
        endDate: d,
      );
    }

    showSmartSuggestions(
      context: context,
      trip: trip,
      weather: _weather,
      onAddSelected: (selected) async {
        for (final s in selected) {
          await vm.addItem(s.categoryId, s.title);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm ${selected.length} mục vào checklist ✅',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
      },
    );
  }

  // ── Date picker ─────────────────────────────────────────────────────────
  Future<void> _pickDate(ChecklistViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
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
    if (picked != null) {
      vm.selectDate(picked);
      _loadWeather(picked); // reload weather theo ngày mới
    }
  }

  // ── Add dialog ──────────────────────────────────────────────────────────
  void _showAddDialog(ChecklistViewModel vm, ChecklistCategory cat) {
    final ctrl = TextEditingController();
    final catColor = Color(cat.colorValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Thêm việc cần làm',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDeep,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              vm.addItem(cat.id, v.trim());
              Navigator.pop(context);
            }
          },
          decoration: InputDecoration(
            hintText: 'Nhập việc cần làm...',
            filled: true,
            fillColor: AppColors.warmCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              backgroundColor: catColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                vm.addItem(cat.id, ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(
              'Thêm',
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

  // ── Edit dialog ─────────────────────────────────────────────────────────
  void _showEditDialog(
    ChecklistViewModel vm,
    ChecklistCategory cat,
    ChecklistItem item,
  ) {
    final ctrl = TextEditingController(text: item.title);
    final catColor = Color(cat.colorValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(cat.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Sửa việc cần làm',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.brownDeep,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tên việc cần làm...',
            filled: true,
            fillColor: AppColors.warmCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: catColor, width: 1.5),
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.brownDeep,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              backgroundColor: catColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty && t != item.title)
                vm.editItem(cat.id, item.id, t);
              Navigator.pop(context);
            },
            child: Text(
              'Lưu',
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

  // ── Delete: confirm dialog thay vì snackbar undo ────────────────────────
  void _confirmDelete(
    ChecklistViewModel vm,
    ChecklistCategory cat,
    ChecklistItem item,
  ) {
    final catColor = Color(cat.colorValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xoá việc này?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDeep,
          ),
        ),
        content: Text(
          item.title,
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
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await vm.deleteItem(cat.id, item.id);
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

  String _fmtDate(DateTime d) {
    const w = ['CN', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    final now = DateTime.now();
    final isToday =
        now.day == d.day && now.month == d.month && now.year == d.year;
    final label = isToday ? 'Hôm nay' : w[d.weekday % 7];
    return '$label, ${d.day}/${d.month}/${d.year}';
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChecklistViewModel>();

    if (vm.isLoading && vm.categories.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.warmCream,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_selectedCat >= vm.categories.length && vm.categories.isNotEmpty) {
      _selectedCat = 0;
    }

    final cat = vm.categories.isNotEmpty ? vm.categories[_selectedCat] : null;
    final catColor = cat != null ? Color(cat.colorValue) : AppColors.primary;

    // FIX: Tính đúng số done/total chỉ trong category đang xem
    final currentItems = cat != null
        ? vm.itemsOfCategory(cat.id)
        : <ChecklistItem>[];
    final currentDone = currentItems.where((i) => i.done).length;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      // FIX: KHÔNG dùng resizeToAvoidBottomInset mặc định
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHECKLIST TẾT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Chuẩn bị đón xuân',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brownDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✨ Smart + Progress
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!vm.isLoading && vm.categories.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showSmartSuggestions(vm),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.gold.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  'Gợi ý',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // FIX: Progress circle dùng tổng ALL categories
                      _ProgressCircle(
                        progress: vm.totalProgress,
                        done: vm.totalDone,
                        total: vm.totalAll,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Tab Theo ngày / Việc chung ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TabBtn(
                      label: 'Theo ngày',
                      icon: Icons.calendar_today_rounded,
                      isActive: !vm.isGeneralMode,
                      activeColor: AppColors.primary,
                      onTap: vm.isGeneralMode
                          ? () async {
                              await vm.switchToDate();
                              _loadWeather(vm.selectedDate);
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TabBtn(
                      label: 'Việc chung',
                      icon: Icons.list_alt_rounded,
                      isActive: vm.isGeneralMode,
                      activeColor: const Color(0xFF8E24AA),
                      onTap: !vm.isGeneralMode ? vm.switchToGeneral : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Date row hoặc info ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: !vm.isGeneralMode
                  ? _DateRow(
                      date: vm.selectedDate,
                      label: _fmtDate(vm.selectedDate),
                      weather: _weather,
                      weatherLoading: _weatherLoading,
                      onTap: () => _pickDate(vm),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E24AA).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF8E24AA).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF8E24AA),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Việc không gắn ngày cụ thể',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E24AA),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 10),

            // ── Progress bar tổng ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: vm.totalProgress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        vm.isGeneralMode
                            ? const Color(0xFF8E24AA)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // FIX: Hiện đúng số — tổng tất cả categories ngày này
                  Text(
                    '${vm.totalDone}/${vm.totalAll} việc hoàn thành'
                    '${vm.isGeneralMode ? ' (chung)' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Category tabs ────────────────────────────────────────────
            if (vm.categories.isNotEmpty)
              SizedBox(
                height: 76,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: vm.categories.length,
                  itemBuilder: (_, i) {
                    final c = vm.categories[i];
                    final isActive = i == _selectedCat;
                    final cColor = Color(c.colorValue);
                    final done = vm.doneInCategory(c.id);
                    final total = vm.totalInCategory(c.id);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCat = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isActive ? cColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isActive
                              ? null
                              : Border.all(color: Colors.grey.shade200),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: cColor.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(c.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(
                              c.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.brownDeep,
                              ),
                            ),
                            Text(
                              '$done/$total',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: isActive
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

            const SizedBox(height: 8),

            // ── Category title + Add ─────────────────────────────────────
            if (cat != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cat.icon} ${cat.title}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brownDeep,
                            ),
                          ),
                          // FIX: hiện số đúng của riêng category này
                          Text(
                            '$currentDone/${currentItems.length} hoàn thành',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddDialog(vm, cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: catColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Thêm',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ── Items list — FIX: padding bottom đủ để không overflow ────
            Expanded(
              child: cat == null
                  ? const SizedBox()
                  : currentItems.isEmpty
                  ? _EmptyDay(
                      color: catColor,
                      isGeneral: vm.isGeneralMode,
                      onSuggest: () => _showSmartSuggestions(vm),
                    )
                  : ListView.builder(
                      // FIX: padding bottom = 120 để tránh FAB + bottom nav
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        MediaQuery.of(context).padding.bottom + 120,
                      ),
                      itemCount: currentItems.length,
                      itemBuilder: (_, i) {
                        final item = currentItems[i];
                        return _ChecklistItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          catColor: catColor,
                          onToggle: () =>
                              vm.toggleItem(cat.id, item.id, !item.done),
                          onEdit: () => _showEditDialog(vm, cat, item),
                          onDelete: () => _confirmDelete(vm, cat, item),
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

// ── Tab button ─────────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date row với weather ───────────────────────────────────────────────────────
class _DateRow extends StatelessWidget {
  final DateTime date;
  final String label;
  final Weather? weather;
  final bool weatherLoading;
  final VoidCallback onTap;

  const _DateRow({
    required this.date,
    required this.label,
    required this.weather,
    required this.weatherLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 17,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownDeep,
                ),
              ),
            ),
            if (weatherLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else if (weather != null) ...[
              Text(weather!.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${weather!.temperature.toStringAsFixed(0)}°',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Đổi ngày',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item tile ──────────────────────────────────────────────────────────────────
class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final Color catColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChecklistItemTile({
    super.key,
    required this.item,
    required this.catColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: item.done ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: item.done ? catColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.done ? catColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: item.done
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    // Chỉ mờ opacity, không gạch ngang
                    color: item.done
                        ? AppColors.brownDeep.withOpacity(0.3)
                        : AppColors.brownDeep,
                  ),
                ),
              ),
              // Edit
              _ActionBtn(
                icon: Icons.edit_outlined,
                color: catColor,
                bgColor: catColor.withOpacity(0.1),
                onTap: onEdit,
              ),
              const SizedBox(width: 6),
              // Delete
              _ActionBtn(
                icon: Icons.delete_outline,
                color: Colors.red.shade300,
                bgColor: Colors.red.shade50,
                onTap: onDelete,
              ),
            ],
          ),
        ), // close AnimatedOpacity
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  final Color color;
  final bool isGeneral;
  final VoidCallback onSuggest;

  const _EmptyDay({
    required this.color,
    required this.isGeneral,
    required this.onSuggest,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isGeneral ? '📋' : '📅', style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              isGeneral ? 'Chưa có việc chung' : 'Ngày này chưa có việc',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onSuggest,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.gold.withOpacity(0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Gợi ý thông minh',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hoặc bấm "Thêm" ở trên ↑',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress circle ────────────────────────────────────────────────────────────
class _ProgressCircle extends StatelessWidget {
  final double progress;
  final int done;
  final int total;

  const _ProgressCircle({
    required this.progress,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '/$total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
