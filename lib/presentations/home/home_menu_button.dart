import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class HomeMenuButtons extends StatelessWidget {
  const HomeMenuButtons({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _MenuItem(icon: Icons.menu_book_rounded, label: 'Sổ tay\nLịch trình'),
      _MenuItem(icon: Icons.checklist_rounded, label: 'Checklist\nHành trang'),
      _MenuItem(icon: Icons.map_rounded, label: 'Bản đồ\nTết'),
      _MenuItem(icon: Icons.assistant_navigation, label: 'Gợi ý\nĐiểm đến'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => _MenuCell(item: item)).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF57534E),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
