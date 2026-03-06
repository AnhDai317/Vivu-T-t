import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/di.dart';
import 'package:vivu_tet/presentations/checklist/checklist_screen.dart';
import 'package:vivu_tet/presentations/home/home_page.dart';
import 'package:vivu_tet/presentations/lucky/cau_may_screen.dart';
import 'package:vivu_tet/presentations/lucky/tai_xiu_screen.dart';
import 'package:vivu_tet/presentations/map/map_screen.dart';
import 'package:vivu_tet/presentations/planner/create_trip_screen.dart';
import 'package:vivu_tet/presentations/profile/profile_screen.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/presentations/shared/widgets/custom_bottom_nav.dart';
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final HomeViewModel _homeVm = buildHome()..loadTrips();
  late final ChecklistViewModel _checklistVm = buildChecklist();

  // Expose để HomePage gọi switch tab
  void switchTab(int index) => setState(() => _selectedIndex = index);

  void _handleNavTap(int index) {
    // index 10 → Thử Vận May (TaiXiu)
    if (index == 10) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TaiXiuScreen()),
      );
      return;
    }
    // index 11 → Cầu May (thắp hương)
    if (index == 11) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CauMayScreen()),
      );
      return;
    }
    // Các tab bình thường 0–3
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _homeVm.dispose();
    _checklistVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _homeVm),
        ChangeNotifierProvider.value(value: _checklistVm),
      ],
      child: Scaffold(
        backgroundColor: AppColors.warmCream,
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomePage(), // 0
            MapScreen(), // 1
            ChecklistScreen(), // 2
            ProfileScreen(), // 3
          ],
        ),
        floatingActionButton: Container(
          height: 60,
          width: 60,
          margin: const EdgeInsets.only(top: 30),
          child: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              );
              if (result == true) _homeVm.loadTrips();
            },
            backgroundColor: AppColors.primary,
            elevation: 6,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.warmCream, width: 4),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTap: _handleNavTap,
        ),
      ),
    );
  }
}
