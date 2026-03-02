import 'package:flutter/material.dart';

import 'package:vivu_tet/presentations/home/home_page.dart';
import 'package:vivu_tet/presentations/shared/widgets/custom_bottom_nav.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/presentations/planner/create_trip_screen.dart'; // Đổi lại đường dẫn nếu bạn lưu file ở chỗ khác
// TODO: Sau này bạn import thêm các màn hình khác (Map, Checklist, Profile) vào đây

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình của từng tab
  final List<Widget> _screens = [
    const HomePage(), // 0: Trang chủ
    const Scaffold(
      body: Center(child: Text("Màn hình Khám phá")),
    ), // 1: Placeholder Map
    const Scaffold(
      body: Center(child: Text("Màn hình Sổ tay Lịch")),
    ), // 2: Placeholder Lịch
    const Scaffold(
      body: Center(child: Text("Màn hình Cài đặt cá nhân")),
    ), // 3: Placeholder Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      // Dùng IndexedStack để giữ nguyên State khi chuyển tab
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // Nút (+) to ở giữa
      floatingActionButton: Container(
        height: 60,
        width: 60,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: () {
            // LỆNH CHUYỂN TRANG NẰM ĐÚNG CHỖ NÀY
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTripScreen()),
            );
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

      // Gọi lại Footer đã tách ra
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
