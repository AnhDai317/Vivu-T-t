import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/presentations/home/widgets/tet_day_model.dart';

class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.day,
    required this.isToday,
    required this.isPast,
  });

  final TetDay day;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFFFF0E0)
              : isPast
              ? Colors.white.withOpacity(0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: AppColors.borderColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isToday ? 0.08 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Emoji + date strip ────────────────────────────────
              Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _tagColor(day.tag).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        day.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HÔM NAY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),

              // ── Nội dung ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nhãn âm lịch
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _tagColor(day.tag).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            day.lunarLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _tagColor(day.tag),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(day.date),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.brownLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tiêu đề
                    Text(
                      day.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPast
                            ? AppColors.brownLight
                            : AppColors.brownDeep,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Mô tả ngắn
                    Text(
                      day.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.brownMid,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Task preview
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 14,
                          color: AppColors.brownLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${day.tasks.length} việc cần làm',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.brownLight,
                          ),
                        ),
                        const Spacer(),
                        if (!isPast)
                          Text(
                            'Xem chi tiết →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
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
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'pre':
        return const Color(0xFFE67E22); // cam – chuẩn bị
      case 'tet':
        return AppColors.primary; // đỏ – ngày Tết
      default:
        return AppColors.brownMid;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(day: day),
    );
  }
}

// ── Detail Bottom Sheet ────────────────────────────────────────────────────────
class _DayDetailSheet extends StatefulWidget {
  const _DayDetailSheet({required this.day});
  final TetDay day;

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(widget.day.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.day.lunarLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          widget.day.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brownDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mô tả
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                widget.day.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.brownMid,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Divider(color: AppColors.borderColor.withOpacity(0.5)),

            // Danh sách việc
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Việc cần làm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brownDeep,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: widget.day.tasks.length,
                itemBuilder: (_, i) {
                  final task = widget.day.tasks[i];
                  return CheckboxListTile(
                    value: task.isDone,
                    activeColor: AppColors.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(
                      task.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: task.isDone
                            ? AppColors.brownLight
                            : AppColors.brownDeep,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: task.note != null
                        ? Text(
                            task.note!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.brownLight,
                            ),
                          )
                        : null,
                    onChanged: (v) => setState(() => task.isDone = v ?? false),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
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
