import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/viewmodel/register/register_viewmodel.dart';

import '../../di.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/vivu_button.dart';
import '../shared/widgets/vivu_text_field.dart';
import 'widgets/auth_toggle.dart';
import 'widgets/dob_picker.dart';
import 'widgets/error_banner.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(RegisterViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await vm.register(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      passWord: _passCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Hãy đăng nhập 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => buildRegister(),
      child: Consumer<RegisterViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.warmCream,
          appBar: AppBar(
            backgroundColor: AppColors.warmCream,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.brownDeep,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Đăng Ký Tài Khoản',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthToggle(
                    isLogin: false,
                    onToggle: (isLogin) {
                      if (isLogin) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Tham gia cùng chúng tôi 🌸',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brownDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Điền thông tin bên dưới để bắt đầu hành trình du xuân.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.brownMid,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Họ và tên ───────────────────────────────────────────
                  const _RequiredLabel('Họ và tên'),
                  const SizedBox(height: 6),
                  ViVuTextField(
                    hint: 'Ví dụ: Nguyễn Văn An',
                    prefixIcon: Icons.badge_outlined,
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => vm.clearError(),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Vui lòng nhập họ tên'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Ngày sinh (DobPicker đã có label bên trong) ──────────
                  const _RequiredLabel('Ngày sinh'),
                  const SizedBox(height: 6),
                  DobPicker(
                    selectedDate: vm.selectedDob,
                    onDateChanged: vm.setDob,
                  ),
                  const SizedBox(height: 16),

                  // ── Email ────────────────────────────────────────────────
                  const _RequiredLabel('Email'),
                  const SizedBox(height: 6),
                  ViVuTextField(
                    hint: 'Nhập địa chỉ email',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => vm.clearError(),
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Mật khẩu ────────────────────────────────────────────
                  const _RequiredLabel('Mật khẩu'),
                  const SizedBox(height: 6),
                  ViVuTextField(
                    hint: 'Tạo mật khẩu bảo mật (≥ 6 ký tự)',
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _passCtrl,
                    obscureText: !vm.isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => vm.clearError(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        vm.isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.brownLight,
                        size: 20,
                      ),
                      onPressed: vm.togglePasswordVisibility,
                    ),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Xác nhận mật khẩu ───────────────────────────────────
                  const _RequiredLabel('Xác nhận mật khẩu'),
                  const SizedBox(height: 6),
                  ViVuTextField(
                    hint: 'Nhập lại mật khẩu',
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _confirmCtrl,
                    obscureText: !vm.isConfirmVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(vm),
                    onChanged: (_) => vm.clearError(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        vm.isConfirmVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.brownLight,
                        size: 20,
                      ),
                      onPressed: vm.toggleConfirmVisibility,
                    ),
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Vui lòng xác nhận mật khẩu'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Điều khoản ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: vm.agreeToTerms,
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: vm.toggleAgreeToTerms,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.brownMid,
                            ),
                            children: const [
                              TextSpan(text: 'Tôi đồng ý với '),
                              TextSpan(
                                text: 'Điều khoản sử dụng',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: ' và '),
                              TextSpan(
                                text: 'Chính sách bảo mật',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (vm.error != null) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(message: vm.error!),
                  ],

                  const SizedBox(height: 24),

                  ViVuButton(
                    label: 'TẠO TÀI KHOẢN',
                    isLoading: vm.loading,
                    onPressed: () => _handleRegister(vm),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.brownMid,
                          ),
                          children: const [
                            TextSpan(text: 'Đã có tài khoản? '),
                            TextSpan(
                              text: 'Đăng nhập ngay',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  final String text;
  const _RequiredLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.brownDeep,
        ),
        children: [
          const TextSpan(
            text: '* ',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}
