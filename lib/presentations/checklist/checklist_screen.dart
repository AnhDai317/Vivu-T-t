import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/domain/entities/checklist_category.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  int _selectedCat = 0;

  void _showAddDialog(
    BuildContext context,
    ChecklistViewModel vm,
    ChecklistCategory cat,
  ) {
    final ctrl = TextEditingController();
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
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
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
              backgroundColor: Color(cat.colorValue),
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChecklistViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.warmCream,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (vm.categories.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.warmCream,
        body: Center(child: Text('Không có dữ liệu')),
      );
    }

    // Đảm bảo index hợp lệ
    if (_selectedCat >= vm.categories.length) {
      _selectedCat = 0;
    }

    final cat = vm.categories[_selectedCat];
    final catColor = Color(cat.colorValue);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  _ProgressCircle(
                    progress: vm.totalProgress,
                    done: vm.totalDone,
                    total: vm.totalAll,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Thanh progress tổng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: vm.totalProgress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vm.totalDone}/${vm.totalAll} việc đã hoàn thành',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Category tabs ────────────────────────────────────────
            SizedBox(
              height: 82,
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
                            '${c.doneCount}/${c.items.length}',
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

            // Tiêu đề danh mục
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat.doneCount}/${cat.items.length} xong',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: catColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Danh sách items ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                itemCount: cat.items.length,
                itemBuilder: (_, i) {
                  final item = cat.items[i];
                  return GestureDetector(
                    onTap: () => vm.toggleItem(cat.id, item.id, !item.done),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: item.done
                            ? catColor.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.done
                              ? catColor.withOpacity(0.2)
                              : Colors.grey.shade100,
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
                          // Checkbox có tích
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: item.done ? catColor : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.done
                                    ? catColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: item.done
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 14),

                          // Text — mờ khi done, không gạch ngang
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: item.done
                                    ? Colors.grey.shade400
                                    : AppColors.brownDeep,
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
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, vm, cat),
        backgroundColor: catColor,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
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
