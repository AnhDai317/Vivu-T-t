import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/presentations/auth/login_page.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/viewmodel/login/login_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginVm = context.read<LoginViewModel>();
    final user = loginVm.session?.user;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Center(
                child: Text(
                  'Cá nhân',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDeep,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Avatar + Name
            Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.festiveGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.fullName ?? 'Người dùng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.brownMid,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Settings list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.notifications_outlined,
                      label: 'Thông báo',
                      trailing: Switch(
                        value: true,
                        onChanged: (_) {},
                        activeColor: AppColors.primary,
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),
                    _SettingRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Chế độ tối',
                      trailing: Switch(
                        value: false,
                        onChanged: (_) {},
                        activeColor: AppColors.primary,
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),
                    _SettingRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Phiên bản',
                      trailing: Text(
                        'v1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.brownMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Logout button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, loginVm),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  label: Text(
                    'Đăng xuất',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, LoginViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDeep,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất không?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.brownMid,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Huỷ',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.brownMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await vm.logout();
      // Xoá toàn bộ stack, về LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.brownMid),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.brownDeep,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
