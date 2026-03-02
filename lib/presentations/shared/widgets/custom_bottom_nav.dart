import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 20,
      shadowColor: Colors.black12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'Trang chủ', 0),
            _buildNavItem(Icons.explore_rounded, 'Khám phá', 1),
            const SizedBox(width: 48), // Khoảng trống cho FAB
            _buildNavItem(Icons.calendar_month_rounded, 'Lịch', 2),
            _buildNavItem(Icons.person_rounded, 'Cài đặt', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? AppColors.primary : Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
