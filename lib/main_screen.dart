import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/di.dart';
import 'package:vivu_tet/presentations/home/home_page.dart';
import 'package:vivu_tet/presentations/lucky/cau_may_screen.dart';
import 'package:vivu_tet/presentations/lucky/tai_xiu_screen.dart';
import 'package:vivu_tet/presentations/planner/create_trip_screen.dart';
import 'package:vivu_tet/presentations/planner/trip_list_screen.dart';
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

  void switchTab(int index) => setState(() => _selectedIndex = index);

  // FIX: chuyển sang index 4 (TripListScreen trong IndexedStack)
  // KHÔNG dùng Navigator.push → footer không bị mất
  void openTripList({DateTime? selectDate}) {
    if (selectDate != null) _homeVm.setSelectedTripDate(selectDate);
    setState(() => _selectedIndex = 4);
  }

  void _handleNavTap(int index) {
    // index 0–3: các tab footer bình thường
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
          children: [
            const HomePage(), // 0 — Trang chủ
            const TaiXiuScreen(), // 1 — Thử Vận May
            const CauMayScreen(), // 2 — Cầu May
            const ProfileScreen(), // 3 — Cá nhân
            // FIX: index 4 — Sổ tay Lịch trình
            // Nằm trong IndexedStack → footer MainScreen vẫn hiển thị
            TripListScreen(onBack: () => setState(() => _selectedIndex = 0)),
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
          // Khi đang ở TripListScreen (index 4), highlight tab Lịch trình (index 0)
          currentIndex: _selectedIndex == 4 ? 0 : _selectedIndex,
          onTap: _handleNavTap,
        ),
      ),
    );
  }
}
