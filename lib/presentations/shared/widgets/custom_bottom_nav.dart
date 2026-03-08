import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Thay Bản đồ + Checklist → Thử Vận May + Cầu May
    // 4 tab: Lịch trình | Thử Vận May | (FAB) | Cầu May | Cá nhân
    const tabs = [
      _TabItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        label: 'Lịch trình',
      ),
      _TabItem(
        icon: Icons.casino_outlined,
        activeIcon: Icons.casino_rounded,
        label: 'Vận May',
      ),
      _TabItem(
        icon: Icons.local_fire_department_outlined,
        activeIcon: Icons.local_fire_department_rounded,
        label: 'Cầu May',
      ),
      _TabItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Cá nhân',
      ),
    ];

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTab(tabs[0], 0),
            _buildTab(tabs[1], 1),
            const SizedBox(width: 56), // khoảng trống cho FAB
            _buildTab(tabs[2], 2),
            _buildTab(tabs[3], 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(_TabItem tab, int index) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: isActive ? AppColors.primary : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
