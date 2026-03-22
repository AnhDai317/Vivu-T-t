import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:vivu_tet/main_screen.dart';
import 'package:vivu_tet/presentations/destinations/destinations_screen.dart';
import 'package:vivu_tet/presentations/map/map_screen.dart';
import 'package:vivu_tet/presentations/checklist/checklist_screen.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';

/// Bốn nút menu chính trên HomePage.
/// BUG ĐÃ FIX: trước đây tất cả onTap: () {} — không làm gì cả.
class HomeMenuButtons extends StatelessWidget {
  const HomeMenuButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.menu_book_rounded,
        label: 'Sổ tay\nLịch trình',
        color: const Color(0xFFE53935),
        onTap: () => _goToTripList(context),
      ),
      _MenuItem(
        icon: Icons.map_rounded,
        label: 'Bản đồ\nDu xuân',
        color: const Color(0xFF1E88E5),
        onTap: () => _goToMap(context),
      ),
      _MenuItem(
        icon: Icons.checklist_rounded,
        label: 'Checklist\nHành trang',
        color: const Color(0xFF43A047),
        onTap: () => _goToChecklist(context),
      ),
      _MenuItem(
        icon: Icons.place_rounded,
        label: 'Gợi ý\nĐiểm đến',
        color: const Color(0xFF8E24AA),
        onTap: () => _goToDestinations(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => _MenuCell(item: item)).toList(),
      ),
    );
  }

  // ── Navigation helpers ──────────────────────────────────────────────────

  void _goToTripList(BuildContext context) {
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    if (mainState != null) {
      mainState.openTripList();
    }
  }

  void _goToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  void _goToChecklist(BuildContext context) {
    final checklistVm = context.read<ChecklistViewModel>();
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

  void _goToDestinations(BuildContext context) {
    final homeVm = context.read<HomeViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: homeVm,
          child: const DestinationsScreen(),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ── Cell widget ───────────────────────────────────────────────────────────────
class _MenuCell extends StatefulWidget {
  const _MenuCell({required this.item});
  final _MenuItem item;

  @override
  State<_MenuCell> createState() => _MenuCellState();
}

class _MenuCellState extends State<_MenuCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.92,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.item.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.item.color.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.item.icon,
                  color: widget.item.color,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.item.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
