import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class TaiXiuScreen extends StatefulWidget {
  const TaiXiuScreen({super.key});

  @override
  State<TaiXiuScreen> createState() => _TaiXiuScreenState();
}

enum _Choice { none, tai, xiu }

enum _GameState { choosing, rolling, result }

class _TaiXiuScreenState extends State<TaiXiuScreen>
    with TickerProviderStateMixin {
  _Choice _userChoice = _Choice.none;
  _GameState _gameState = _GameState.choosing;

  // Kết quả 3 xúc xắc
  List<int> _diceValues = [1, 1, 1];
  int get _total => _diceValues.fold(0, (a, b) => a + b);
  bool get _isTai => _total >= 11;
  bool get _isWin =>
      (_userChoice == _Choice.tai && _isTai) ||
      (_userChoice == _Choice.xiu && !_isTai);

  // Animation controllers
  late AnimationController _shakeCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _particleCtrl;
  late List<AnimationController> _diceCtrl;
  late List<Animation<double>> _diceAnim;

  // Lịch sử
  final List<Map<String, dynamic>> _history = [];

  // Thống kê
  int _wins = 0;
  int _losses = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _diceCtrl = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + i * 150),
      ),
    );
    _diceAnim = _diceCtrl
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _resultCtrl.dispose();
    _particleCtrl.dispose();
    for (final c in _diceCtrl) c.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    if (_userChoice == _Choice.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hãy chọn Tài hoặc Xỉu trước! 🎲',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _gameState = _GameState.rolling);

    // Animate shake
    _shakeCtrl.forward(from: 0);

    // Random values while rolling
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        setState(() {
          _diceValues = List.generate(3, (_) => Random().nextInt(6) + 1);
        });
      }
    }

    // Final result
    final rng = Random();
    final finalValues = List.generate(3, (_) => rng.nextInt(6) + 1);
    if (mounted) setState(() => _diceValues = finalValues);

    // Show result
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _gameState = _GameState.result);
      _resultCtrl.forward(from: 0);

      if (_isWin) {
        _particleCtrl.forward(from: 0);
        _wins++;
        HapticFeedback.heavyImpact();
      } else {
        _losses++;
        HapticFeedback.lightImpact();
      }

      // Lưu lịch sử
      _history.insert(0, {
        'dice': List<int>.from(finalValues),
        'total': _total,
        'isTai': _isTai,
        'choice': _userChoice,
        'win': _isWin,
      });
      if (_history.length > 5) _history.removeLast();
    }
  }

  void _reset() {
    setState(() {
      _userChoice = _Choice.none;
      _gameState = _GameState.choosing;
      _diceValues = [1, 1, 1];
    });
    _resultCtrl.reset();
    _particleCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
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
                        color: Colors.white.withOpacity(0.1),
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
                    '🎲 Thử Vận May',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Thống kê
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '🏆$_wins',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '💀$_losses',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    // ── Bàn chơi ────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2D1200),
                            const Color(0xFF1A0A00),
                          ],
                          radius: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Chọn Tài / Xỉu
                          Text(
                            'CHỌN CỦA BẠN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFD700),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _ChoiceBtn(
                                  label: 'TÀI',
                                  subtitle: '11 – 18',
                                  emoji: '🔴',
                                  isSelected: _userChoice == _Choice.tai,
                                  enabled: _gameState == _GameState.choosing,
                                  onTap: () =>
                                      setState(() => _userChoice = _Choice.tai),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ChoiceBtn(
                                  label: 'XỈU',
                                  subtitle: '3 – 10',
                                  emoji: '⚫',
                                  isSelected: _userChoice == _Choice.xiu,
                                  enabled: _gameState == _GameState.choosing,
                                  onTap: () =>
                                      setState(() => _userChoice = _Choice.xiu),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // 3 xúc xắc
                          AnimatedBuilder(
                            animation: _shakeCtrl,
                            builder: (_, child) {
                              final shake =
                                  sin(_shakeCtrl.value * pi * 10) *
                                  (_gameState == _GameState.rolling
                                      ? 8.0
                                      : 0.0);
                              return Transform.translate(
                                offset: Offset(shake, 0),
                                child: child,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: _DiceWidget(
                                    value: _diceValues[i],
                                    isRolling: _gameState == _GameState.rolling,
                                    index: i,
                                  ),
                                );
                              }),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tổng điểm
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _gameState != _GameState.choosing
                                ? Column(
                                    key: ValueKey(_total),
                                    children: [
                                      Text(
                                        'TỔNG: $_total',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: _gameState == _GameState.result
                                              ? (_isTai
                                                    ? const Color(0xFFFF4444)
                                                    : Colors.grey.shade300)
                                              : Colors.white,
                                        ),
                                      ),
                                      if (_gameState == _GameState.result)
                                        Text(
                                          _isTai ? '🔴 TÀI' : '⚫ XỈU',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _isTai
                                                ? const Color(0xFFFF4444)
                                                : Colors.grey.shade400,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                    ],
                                  )
                                : const SizedBox(
                                    key: ValueKey('empty'),
                                    height: 36,
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // Kết quả thắng/thua
                          if (_gameState == _GameState.result)
                            ScaleTransition(
                              scale: CurvedAnimation(
                                parent: _resultCtrl,
                                curve: Curves.elasticOut,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _isWin
                                      ? const Color(
                                          0xFFFFD700,
                                        ).withOpacity(0.15)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isWin
                                        ? const Color(
                                            0xFFFFD700,
                                          ).withOpacity(0.5)
                                        : Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _isWin ? '🎉 CHÚC MỪNG!' : '😔 TIẾC QUÁ!',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: _isWin
                                            ? const Color(0xFFFFD700)
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isWin
                                          ? 'Bạn đoán đúng! Vận may đang mỉm cười ✨'
                                          : 'Đừng nản, thử lại lần nữa nhé 💪',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Nút lắc / thử lại
                          if (_gameState == _GameState.result)
                            GestureDetector(
                              onTap: _reset,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  '🔄  Chơi lại',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _gameState == _GameState.choosing
                                  ? _roll
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _userChoice != _Choice.none
                                        ? [
                                            const Color(0xFFFFD700),
                                            const Color(0xFFFFA500),
                                          ]
                                        : [
                                            Colors.grey.shade800,
                                            Colors.grey.shade700,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: _userChoice != _Choice.none
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFFD700,
                                            ).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '🎲',
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _gameState == _GameState.rolling
                                          ? 'Đang lắc...'
                                          : 'LẮC XÚC XẮC',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _userChoice != _Choice.none
                                            ? const Color(0xFF1A0A00)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Lịch sử ─────────────────────────────────────────────
                    if (_history.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '📜 Lịch sử gần đây',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_history.map((h) => _HistoryRow(data: h))),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Choice Button ─────────────────────────────────────────────────────────────
class _ChoiceBtn extends StatelessWidget {
  final String label;
  final String subtitle;
  final String emoji;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _ChoiceBtn({
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (label == 'TÀI'
                    ? const Color(0xFFFF4444).withOpacity(0.2)
                    : Colors.grey.shade800)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (label == 'TÀI'
                      ? const Color(0xFFFF4444)
                      : Colors.grey.shade400)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (label == 'TÀI'
                                ? const Color(0xFFFF4444)
                                : Colors.grey.shade600)
                            .withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? (label == 'TÀI'
                          ? const Color(0xFFFF4444)
                          : Colors.grey.shade300)
                    : Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dice Widget ───────────────────────────────────────────────────────────────
class _DiceWidget extends StatelessWidget {
  final int value;
  final bool isRolling;
  final int index;

  const _DiceWidget({
    required this.value,
    required this.isRolling,
    required this.index,
  });

  // Dot positions cho mỗi mặt xúc xắc
  static const _dots = {
    1: [(0.5, 0.5)],
    2: [(0.25, 0.25), (0.75, 0.75)],
    3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
    4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
    5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
    6: [
      (0.25, 0.25),
      (0.75, 0.25),
      (0.25, 0.5),
      (0.75, 0.5),
      (0.25, 0.75),
      (0.75, 0.75),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final positions = _dots[value] ?? [];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isRolling ? const Color(0xFF3D1F00) : const Color(0xFFF5E6C8),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isRolling
                ? const Color(0xFFFFD700).withOpacity(0.3)
                : Colors.black.withOpacity(0.4),
            blurRadius: isRolling ? 16 : 8,
            offset: const Offset(0, 4),
          ),
          if (!isRolling)
            const BoxShadow(
              color: Colors.white24,
              blurRadius: 2,
              offset: Offset(-1, -1),
            ),
        ],
      ),
      child: CustomPaint(
        painter: _DicePainter(
          dots: positions,
          dotColor: const Color(0xFF1A0A00),
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final List<(double, double)> dots;
  final Color dotColor;

  _DicePainter({required this.dots, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    final radius = size.width * 0.09;
    for (final (x, y) in dots) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) => old.dots != dots;
}

// ── History Row ───────────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final dice = data['dice'] as List<int>;
    final total = data['total'] as int;
    final isTai = data['isTai'] as bool;
    final win = data['win'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Xúc xắc nhỏ
          Row(
            children: dice
                .map(
                  (d) => Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6C8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A0A00),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 10),
          Text(
            '= $total',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isTai
                  ? const Color(0xFFFF4444).withOpacity(0.2)
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isTai ? 'TÀI' : 'XỈU',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isTai ? const Color(0xFFFF4444) : Colors.grey.shade400,
              ),
            ),
          ),
          const Spacer(),
          Text(
            win ? '✅ Thắng' : '❌ Thua',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: win ? const Color(0xFFFFD700) : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
