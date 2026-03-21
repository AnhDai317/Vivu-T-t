import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/domain/entities/checklist_item.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  int _selectedCat = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChecklistViewModel>();
      if (vm.categories.isEmpty && !vm.isLoading) {
        vm.loadCategories();
      }
    });
  }

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
    if (picked != null) vm.selectDate(picked);
  }

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
              if (t.isNotEmpty && t != item.title) {
                vm.editItem(cat.id, item.id, t);
              }
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

  Future<void> _deleteWithUndo(
    ChecklistViewModel vm,
    ChecklistCategory cat,
    ChecklistItem item,
  ) async {
    final removed = await vm.deleteItem(cat.id, item.id);
    if (removed == null || !mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã xoá "${removed.title}"',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.brownDeep,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: AppColors.gold,
          onPressed: () => vm.undoDelete(cat.id, removed),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const w = ['CN', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    final isToday =
        DateTime.now().day == d.day &&
        DateTime.now().month == d.month &&
        DateTime.now().year == d.year;
    final label = isToday ? 'Hôm nay' : w[d.weekday % 7];
    return '$label, ${d.day}/${d.month}/${d.year}';
  }

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

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      // FIX: Không có floatingActionButton ở đây
      // Nút Thêm đã nằm trong header row bên cạnh tên category
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 12),
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
                      Column(
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brownDeep,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _ProgressCircle(
                    progress: vm.totalProgress,
                    done: vm.totalDone,
                    total: vm.totalAll,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Tab Theo ngày / Công việc chung ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: vm.isGeneralMode ? () => vm.switchToDate() : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !vm.isGeneralMode
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !vm.isGeneralMode
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: !vm.isGeneralMode
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Theo ngày',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: !vm.isGeneralMode
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: !vm.isGeneralMode
                          ? () => vm.switchToGeneral()
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: vm.isGeneralMode
                              ? const Color(0xFF8E24AA)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: vm.isGeneralMode
                                ? const Color(0xFF8E24AA)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 14,
                              color: vm.isGeneralMode
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Việc chung',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: vm.isGeneralMode
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Date picker / Info label ──────────────────────────────
            if (!vm.isGeneralMode)
              GestureDetector(
                onTap: () => _pickDate(vm),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fmtDate(vm.selectedDate),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brownDeep,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
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
                        'Những việc không cần gắn ngày cụ thể',
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

            // ── Progress bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: vm.totalProgress,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        vm.isGeneralMode
                            ? const Color(0xFF8E24AA)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${vm.totalDone}/${vm.totalAll} việc đã xong'
                    '${vm.isGeneralMode ? ' (chung)' : ' hôm nay'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Category tabs ─────────────────────────────────────────
            if (vm.categories.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: vm.categories.length,
                  itemBuilder: (_, i) {
                    final c = vm.categories[i];
                    final isActive = i == _selectedCat;
                    final cColor = Color(c.colorValue);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCat = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 82,
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
                            Text(c.icon, style: const TextStyle(fontSize: 22)),
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
                              '${vm.doneInCategory(c.id)}/${vm.totalInCategory(c.id)}',
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

            // ── Tiêu đề category + NÚT THÊM (chỉ 1 nút duy nhất) ────
            if (cat != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${cat.icon} ${cat.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brownDeep,
                      ),
                    ),
                    // Đây là NÚT THÊM DUY NHẤT — không có FAB nào khác
                    GestureDetector(
                      onTap: () => _showAddDialog(vm, cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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

            // ── Items list ────────────────────────────────────────────
            Expanded(
              child: cat == null
                  ? const SizedBox()
                  : vm.itemsOfCategory(cat.id).isEmpty
                  ? _EmptyDay(color: catColor, isGeneral: vm.isGeneralMode)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                      itemCount: vm.itemsOfCategory(cat.id).length,
                      itemBuilder: (_, i) {
                        final item = vm.itemsOfCategory(cat.id)[i];
                        return _ChecklistItemTile(
                          item: item,
                          catColor: catColor,
                          onToggle: () =>
                              vm.toggleItem(cat.id, item.id, !item.done),
                          onEdit: () => _showEditDialog(vm, cat, item),
                          onDelete: () => _deleteWithUndo(vm, cat, item),
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

// ── Item Tile ─────────────────────────────────────────────────────────────────
class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final Color catColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChecklistItemTile({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: item.done ? catColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.done ? catColor.withOpacity(0.2) : Colors.grey.shade100,
          ),
          boxShadow: item.done
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.done ? catColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.done ? catColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: item.done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: item.done ? Colors.grey.shade400 : AppColors.brownDeep,
                  decoration: item.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined, size: 15, color: catColor),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 15,
                  color: Colors.red.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  final Color color;
  final bool isGeneral;
  const _EmptyDay({required this.color, required this.isGeneral});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isGeneral ? '📋' : '📅', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            isGeneral ? 'Chưa có việc chung nào' : 'Ngày này chưa có việc gì',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.brownDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isGeneral
                ? 'Thêm việc không gắn ngày cụ thể'
                : 'Thêm việc cần chuẩn bị cho ngày này',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                'Bấm nút "Thêm" ở trên để bắt đầu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress circle ───────────────────────────────────────────────────────────
class _ProgressCircle extends StatelessWidget {
  final double progress;
  final int done, total;
  const _ProgressCircle({
    required this.progress,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '/$total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
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
