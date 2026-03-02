import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/presentations/home/home_page.dart';
import 'package:vivu_tet/viewmodel/login/login_viewmodel.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/vivu_button.dart';
import '../shared/widgets/vivu_text_field.dart';
import 'register_page.dart';
import 'widgets/auth_toggle.dart';
import 'widgets/error_banner.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final vm = context.read<LoginViewModel>();
    final ok = await vm.login(_emailCtrl.text, _passCtrl.text);

    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Banner ──────────────────────────────────────
              _HeroBanner(),

              // ── Welcome Text ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    Text(
                      'Chào mừng bạn đến với\nViVu Tết 🏮',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brownDeep,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lên kế hoạch cho kỳ nghỉ Tết trọn vẹn của bạn',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.brownMid,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Toggle ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AuthToggle(
                  isLogin: true,
                  onToggle: (isLogin) {
                    if (!isLogin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    }
                  },
                ),
              ),

              // ── Form ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Consumer<LoginViewModel>(
                  builder: (context, vm, _) => Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        ViVuTextField(
                          label: 'Email hoặc Số điện thoại',
                          hint: 'Nhập email hoặc số điện thoại',
                          prefixIcon: Icons.person_outline_rounded,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => vm.clearError(),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Vui lòng nhập email'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        ViVuTextField(
                          label: 'Mật khẩu',
                          hint: 'Nhập mật khẩu',
                          prefixIcon: Icons.lock_outline_rounded,
                          controller: _passCtrl,
                          obscureText: !vm.isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
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
                          validator: (v) => (v?.isEmpty ?? true)
                              ? 'Vui lòng nhập mật khẩu'
                              : null,
                        ),

                        // Quên mật khẩu
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Quên mật khẩu?',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Error ────────────────────────────────────────────
              Consumer<LoginViewModel>(
                builder: (_, vm, __) {
                  if (vm.error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: ErrorBanner(message: vm.error!),
                  );
                },
              ),

              // ── Nút ĐĂNG NHẬP ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Consumer<LoginViewModel>(
                  builder: (_, vm, __) => ViVuButton(
                    label: 'ĐĂNG NHẬP',
                    isLoading: vm.loading,
                    onPressed: _handleLogin,
                  ),
                ),
              ),

              // ── Terms ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
                child: Text(
                  'Bằng cách tiếp tục, bạn đồng ý với Điều khoản dịch vụ '
                  'và Chính sách quyền riêng tư của chúng tôi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.brownMid,
                  ),
                ),
              ),

              const _LuckyEnvelope(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8D5C4), Color(0xFFF5E6D3)],
              ),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Text('🌸 🏮 🌸', style: TextStyle(fontSize: 44)),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 70,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.warmCream.withOpacity(0),
                    AppColors.warmCream,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckyEnvelope extends StatelessWidget {
  const _LuckyEnvelope();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 24, top: 8),
        child: Transform.rotate(
          angle: 0.2,
          child: Opacity(
            opacity: 0.3,
            child: Container(
              width: 52,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: AppColors.gold,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
