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
            // ── Header ──────────────────────────────────────────────────────
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

            // ── Avatar + tên ─────────────────────────────────────────────────
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

            // ── Settings list ─────────────────────────────────────────────────
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
                    // Đổi mật khẩu
                    _SettingRow(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF1E88E5),
                      label: 'Đổi mật khẩu',
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () =>
                          _showChangePasswordSheet(context, loginVm),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),
                    // Phiên bản
                    _SettingRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF8E24AA),
                      label: 'Phiên bản',
                      trailing: Text(
                        'v1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.brownMid,
                        ),
                      ),
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Đăng xuất ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, loginVm),
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 20),
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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet đổi mật khẩu ────────────────────────────────────────────
  void _showChangePasswordSheet(
      BuildContext context, LoginViewModel loginVm) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          bool obscureOld = true;
          bool obscureNew = true;
          bool obscureConfirm = true;
          bool isLoading = false;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Đổi mật khẩu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brownDeep,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mật khẩu hiện tại
                  StatefulBuilder(
                    builder: (_, setOld) => TextFormField(
                      controller: oldCtrl,
                      obscureText: obscureOld,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDeco(
                        label: 'Mật khẩu hiện tại',
                        suffix: IconButton(
                          icon: Icon(
                            obscureOld
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setOld(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vui lòng nhập mật khẩu cũ'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mật khẩu mới
                  StatefulBuilder(
                    builder: (_, setNew) => TextFormField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDeco(
                        label: 'Mật khẩu mới',
                        suffix: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setNew(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (v.length < 6) {
                          return 'Tối thiểu 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Xác nhận mật khẩu mới
                  StatefulBuilder(
                    builder: (_, setConfirm) => TextFormField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDeco(
                        label: 'Xác nhận mật khẩu mới',
                        suffix: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => setConfirm(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (v) => v != newCtrl.text
                          ? 'Mật khẩu không khớp'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút lưu
                  StatefulBuilder(
                    builder: (_, setBtn) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                setBtn(() => isLoading = true);
                                try {
                                  await loginVm.changePassword(
                                    oldPassword: oldCtrl.text,
                                    newPassword: newCtrl.text,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(_snackbar(
                                      '✅ Đổi mật khẩu thành công!',
                                      Colors.green.shade600,
                                    ));
                                  }
                                } catch (e) {
                                  setBtn(() => isLoading = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(_snackbar(
                                      '❌ Mật khẩu hiện tại không đúng',
                                      Colors.red.shade400,
                                    ));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Lưu thay đổi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Logout confirm ────────────────────────────────────────────────────────
  Future<void> _handleLogout(
      BuildContext context, LoginViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất?',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, color: AppColors.brownDeep),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất không?',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: AppColors.brownMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.brownMid,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Đăng xuất',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await vm.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  InputDecoration _inputDeco(
      {required String label, required Widget suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  SnackBar _snackbar(String msg, Color color) => SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );
}

// ── Setting row ───────────────────────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
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
      ),
    );
  }
}