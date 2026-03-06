import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class CauMayScreen extends StatefulWidget {
  const CauMayScreen({super.key});

  @override
  State<CauMayScreen> createState() => _CauMayScreenState();
}

class _CauMayScreenState extends State<CauMayScreen>
    with TickerProviderStateMixin {
  bool _isIncenseLit = false; // Đang thắp
  bool _soundOn = true; // Nhạc bật
  bool _smokeOn = true; // Khói bật
  String _selectedPrayer = ''; // Lời cầu nguyện đã chọn
  bool _prayerSent = false; // Đã gửi lời cầu

  // Smoke particles
  late AnimationController _smokeCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _flameCtrl;
  late AnimationController _bellCtrl;

  final List<_SmokeParticle> _particles = [];
  final _rng = Random();

  static const _prayers = [
    ('🏥', 'Sức khoẻ bình an', 'Cầu cho gia đình mạnh khoẻ, bình an năm mới'),
    (
      '💰',
      'Tài lộc dồi dào',
      'Cầu mong công việc thuận lợi, tiền tài phát đạt',
    ),
    (
      '📚',
      'Học hành giỏi giang',
      'Cầu cho con cháu học giỏi, thi đỗ thành tài',
    ),
    (
      '💕',
      'Tình duyên viên mãn',
      'Cầu mong hôn nhân hạnh phúc, gia đình êm ấm',
    ),
    ('🌟', 'Vạn sự như ý', 'Cầu mong năm mới mọi điều tốt lành như ý nguyện'),
  ];

  @override
  void initState() {
    super.initState();

    _smokeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_spawnSmoke);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _smokeCtrl.dispose();
    _glowCtrl.dispose();
    _flameCtrl.dispose();
    _bellCtrl.dispose();
    super.dispose();
  }

  void _spawnSmoke() {
    if (!_smokeOn) return;
    if (_rng.nextDouble() < 0.3) {
      setState(() {
        _particles.add(
          _SmokeParticle(
            x: 0.5 + (_rng.nextDouble() - 0.5) * 0.06,
            speed: 0.004 + _rng.nextDouble() * 0.003,
            drift: (_rng.nextDouble() - 0.5) * 0.003,
            size: 8 + _rng.nextDouble() * 14,
            opacity: 0.3 + _rng.nextDouble() * 0.3,
          ),
        );
        // Cập nhật vị trí
        for (final p in _particles) {
          p.y -= p.speed;
          p.x += p.drift;
          p.opacity -= 0.008;
        }
        _particles.removeWhere((p) => p.opacity <= 0 || p.y < 0);
        if (_particles.length > 30) _particles.removeAt(0);
      });
    } else {
      setState(() {
        for (final p in _particles) {
          p.y -= p.speed;
          p.x += p.drift;
          p.opacity -= 0.008;
        }
        _particles.removeWhere((p) => p.opacity <= 0 || p.y < 0);
      });
    }
  }

  void _toggleIncense() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isIncenseLit = !_isIncenseLit;
      _prayerSent = false;
    });

    if (_isIncenseLit) {
      _smokeCtrl.repeat();
    } else {
      _smokeCtrl.stop();
      setState(() => _particles.clear());
    }
  }

  void _sendPrayer() {
    if (_selectedPrayer.isEmpty) return;
    HapticFeedback.heavyImpact();
    _bellCtrl.forward(from: 0).then((_) => _bellCtrl.reverse());
    setState(() => _prayerSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0500),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '🙏 Cầu May',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Toggle nhạc & khói
                  Row(
                    children: [
                      _ToggleBtn(
                        icon: _soundOn
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        active: _soundOn,
                        onTap: () => setState(() => _soundOn = !_soundOn),
                      ),
                      const SizedBox(width: 8),
                      _ToggleBtn(
                        icon: Icons.blur_on_rounded,
                        active: _smokeOn,
                        onTap: () => setState(() {
                          _smokeOn = !_smokeOn;
                          if (!_smokeOn) _particles.clear();
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Bàn thờ ─────────────────────────────────────────────
                    Container(
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Nền mờ gradient
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _glowCtrl,
                              builder: (_, __) => Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFFF6B00).withOpacity(
                                        0.08 +
                                            _glowCtrl.value *
                                                0.06 *
                                                (_isIncenseLit ? 1 : 0),
                                      ),
                                      Colors.transparent,
                                    ],
                                    radius: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Khói particles
                          if (_smokeOn && _isIncenseLit)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _SmokePainter(
                                  particles: _particles,
                                  baseY: 0.55,
                                ),
                              ),
                            ),

                          // Lư hương
                          Positioned(
                            bottom: 20,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Que hương
                                AnimatedBuilder(
                                  animation: _flameCtrl,
                                  builder: (_, __) => Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      // Que hương thân
                                      Container(
                                        width: 3,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color(0xFF8B4513),
                                              const Color(0xFF4A2000),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      // Đầu hồng (phần đã cháy)
                                      if (_isIncenseLit)
                                        Positioned(
                                          top: 0,
                                          child: Container(
                                            width: 6,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  const Color(0xFFFF4500),
                                                  const Color(
                                                    0xFFFF6B35,
                                                  ).withOpacity(0.5),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF4500)
                                                      .withOpacity(
                                                        0.6 +
                                                            _flameCtrl.value *
                                                                0.3,
                                                      ),
                                                  blurRadius:
                                                      10 + _flameCtrl.value * 5,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Lư hương (bát)
                                AnimatedBuilder(
                                  animation: _glowCtrl,
                                  builder: (_, __) => Container(
                                    width: 80,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(0xFFB8860B),
                                          const Color(0xFF8B6914),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(40),
                                        topRight: Radius.circular(40),
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700)
                                              .withOpacity(
                                                _isIncenseLit
                                                    ? 0.3 +
                                                          _glowCtrl.value * 0.2
                                                    : 0.1,
                                              ),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '香',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: const Color(
                                            0xFFFFD700,
                                          ).withOpacity(0.8),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nến 2 bên
                          _buildCandle(left: true),
                          _buildCandle(left: false),

                          // Nút thắp / tắt
                          Positioned(
                            top: 20,
                            child: GestureDetector(
                              onTap: _toggleIncense,
                              child: AnimatedBuilder(
                                animation: _glowCtrl,
                                builder: (_, __) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isIncenseLit
                                          ? [
                                              const Color(0xFFFF6B00),
                                              const Color(0xFFFF4500),
                                            ]
                                          : [
                                              const Color(0xFFB8860B),
                                              const Color(0xFF8B6914),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isIncenseLit
                                                    ? const Color(0xFFFF6B00)
                                                    : const Color(0xFFB8860B))
                                                .withOpacity(
                                                  0.4 +
                                                      (_isIncenseLit
                                                          ? _glowCtrl.value *
                                                                0.2
                                                          : 0),
                                                ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isIncenseLit ? '🕯️' : '🔥',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isIncenseLit
                                            ? 'Tắt hương'
                                            : 'Thắp hương',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Chọn lời cầu nguyện ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn điều bạn cầu nguyện:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),

                          ..._prayers.map(
                            (p) => GestureDetector(
                              onTap: () => setState(() {
                                _selectedPrayer = p.$1;
                                _prayerSent = false;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _selectedPrayer == p.$1
                                      ? const Color(0xFFB8860B).withOpacity(0.2)
                                      : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _selectedPrayer == p.$1
                                        ? const Color(
                                            0xFFFFD700,
                                          ).withOpacity(0.5)
                                        : Colors.white.withOpacity(0.08),
                                    width: _selectedPrayer == p.$1 ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      p.$1,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.$2,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _selectedPrayer == p.$1
                                                  ? const Color(0xFFFFD700)
                                                  : Colors.white,
                                            ),
                                          ),
                                          Text(
                                            p.$3,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedPrayer == p.$1)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFFFD700),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Nút gửi lời cầu
                          if (_prayerSent)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFB8860B).withOpacity(0.3),
                                    const Color(0xFFFFD700).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.4),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '🙏',
                                    style: TextStyle(fontSize: 36),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Lời cầu nguyện đã được gửi đi!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFFFD700),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nguyện xin tâm thành ý đạt, vạn sự như ý 🌟',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _selectedPrayer.isNotEmpty
                                  ? _sendPrayer
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _selectedPrayer.isNotEmpty
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFB8860B),
                                            Color(0xFFFFD700),
                                          ],
                                        )
                                      : null,
                                  color: _selectedPrayer.isEmpty
                                      ? Colors.white.withOpacity(0.05)
                                      : null,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: _selectedPrayer.isNotEmpty
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFFD700,
                                            ).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '🙏',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Gửi lời cầu nguyện',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _selectedPrayer.isNotEmpty
                                            ? const Color(0xFF0D0500)
                                            : Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandle({required bool left}) {
    return Positioned(
      bottom: 20,
      left: left ? 30 : null,
      right: left ? null : 30,
      child: AnimatedBuilder(
        animation: _flameCtrl,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isIncenseLit)
              Container(
                width: 8,
                height: 12 + _flameCtrl.value * 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFFFFFF99), const Color(0xFFFFA500)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA500).withOpacity(0.6),
                      blurRadius: 8 + _flameCtrl.value * 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            Container(
              width: 16,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFE4B5),
                    Color(0xFFFFF8DC),
                    Color(0xFFFFE4B5),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: _isIncenseLit
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFFA500,
                          ).withOpacity(0.2 + _glowCtrl.value * 0.15),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Smoke Painter ─────────────────────────────────────────────────────────────
class _SmokeParticle {
  double x;
  double y;
  double speed;
  double drift;
  double size;
  double opacity;

  _SmokeParticle({
    required this.x,
    required this.speed,
    required this.drift,
    required this.size,
    required this.opacity,
  }) : y = 0.55;
}

class _SmokePainter extends CustomPainter {
  final List<_SmokeParticle> particles;
  final double baseY;

  _SmokePainter({required this.particles, required this.baseY});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(p.opacity.clamp(0.0, 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(
        Offset(size.width * p.x, size.height * p.y),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => true;
}

// ── Toggle Button ─────────────────────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFB8860B).withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}
