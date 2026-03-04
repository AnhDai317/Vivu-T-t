import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/di.dart';
import 'package:vivu_tet/presentations/checklist/checklist_screen.dart';
import 'package:vivu_tet/presentations/home/home_page.dart';
import 'package:vivu_tet/presentations/map/map_screen.dart';
import 'package:vivu_tet/presentations/planner/create_trip_screen.dart';
import 'package:vivu_tet/presentations/planner/trip_list_screen.dart';
import 'package:vivu_tet/presentations/profile/profile_screen.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/presentations/shared/widgets/custom_bottom_nav.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 0=Lịch trình, 1=Bản đồ, 2=Checklist, 3=Cá nhân
  int _selectedIndex = 0;

  late final HomeViewModel _homeVm = buildHome()..loadTrips();

  @override
  void dispose() {
    _homeVm.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _homeVm,
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
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
