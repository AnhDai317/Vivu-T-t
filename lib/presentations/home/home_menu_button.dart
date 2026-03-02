import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class HomeMenuButtons extends StatelessWidget {
  const HomeMenuButtons({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _MenuItem(icon: Icons.local_florist_rounded, label: 'Hoa Đào'),
      _MenuItem(icon: Icons.redeem_rounded, label: 'Lì Xì'),
      _MenuItem(icon: Icons.temple_buddhist_rounded, label: 'Lễ Chùa'),
      _MenuItem(icon: Icons.restaurant_rounded, label: 'Mỹ Vị'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _MenuCell(item: item),
                ),
              ),
            )
            .toList(),
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            item.label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF57534E), // stone-600
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
