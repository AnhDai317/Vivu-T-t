import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

// ── Dữ liệu 6 mặt Bầu Cua ────────────────────────────────────────────────────
enum BauCuaSymbol { bau, cua, tom, ca, ga, nai }

extension BauCuaExt on BauCuaSymbol {
  String get emoji {
    switch (this) {
      case BauCuaSymbol.bau:
        return '🎃';
      case BauCuaSymbol.cua:
        return '🦀';
      case BauCuaSymbol.tom:
        return '🦐';
      case BauCuaSymbol.ca:
        return '🐟';
      case BauCuaSymbol.ga:
        return '🐓';
      case BauCuaSymbol.nai:
        return '🦌';
    }
  }

  String get label {
    switch (this) {
      case BauCuaSymbol.bau:
        return 'Bầu';
      case BauCuaSymbol.cua:
        return 'Cua';
      case BauCuaSymbol.tom:
        return 'Tôm';
      case BauCuaSymbol.ca:
        return 'Cá';
      case BauCuaSymbol.ga:
        return 'Gà';
      case BauCuaSymbol.nai:
        return 'Nai';
    }
  }

  Color get color {
    switch (this) {
      case BauCuaSymbol.bau:
        return const Color(0xFF43A047);
      case BauCuaSymbol.cua:
        return const Color(0xFFE53935);
      case BauCuaSymbol.tom:
        return const Color(0xFFFF7043);
      case BauCuaSymbol.ca:
        return const Color(0xFF1E88E5);
      case BauCuaSymbol.ga:
        return const Color(0xFFF9A825);
      case BauCuaSymbol.nai:
        return const Color(0xFF8E24AA);
    }
  }
}

const _allSymbols = BauCuaSymbol.values;

// ── Game State ────────────────────────────────────────────────────────────────
enum _Phase { betting, rolling, result }

class BauCuaScreen extends StatefulWidget {
  const BauCuaScreen({super.key});

  @override
  State<BauCuaScreen> createState() => _BauCuaScreenState();
}

class _BauCuaScreenState extends State<BauCuaScreen>
    with TickerProviderStateMixin {
  final _rng = Random();

  // Tiền ảo
  int _coins = 1000;
  // Cược: symbol → số tiền đặt
  final Map<BauCuaSymbol, int> _bets = {};
  int _betAmount = 50; // mệnh giá đặt cược hiện tại

  // Kết quả 3 xúc xắc
  List<BauCuaSymbol> _dice = [
    BauCuaSymbol.bau,
    BauCuaSymbol.cua,
    BauCuaSymbol.tom,
  ];

  _Phase _phase = _Phase.betting;

  // Kết quả vòng vừa rồi
  int _lastWin = 0;
  int _totalBet = 0;

  // History
  final List<Map<String, dynamic>> _history = [];

  // Animations
  late AnimationController _shakeCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _glowCtrl;

  // Số vòng thắng/thua
  int _wins = 0, _losses = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _resultCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  int get _totalBetAmount => _bets.values.fold(0, (a, b) => a + b);

  // Đặt cược vào 1 ô
  void _placeBet(BauCuaSymbol sym) {
    if (_phase != _Phase.betting) return;
    if (_coins < _betAmount) {
      _showSnack('Không đủ xu! 😅');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _bets[sym] = (_bets[sym] ?? 0) + _betAmount;
      _coins -= _betAmount;
    });
  }

  // Xoá cược ở 1 ô
  void _clearBet(BauCuaSymbol sym) {
    if (_phase != _Phase.betting) return;
    final bet = _bets[sym] ?? 0;
    if (bet == 0) return;
    setState(() {
      _coins += bet;
      _bets.remove(sym);
    });
  }

  // Xoá tất cả cược
  void _clearAllBets() {
    if (_phase != _Phase.betting) return;
    setState(() {
      _coins += _totalBetAmount;
      _bets.clear();
    });
  }

  Future<void> _roll() async {
    if (_bets.isEmpty) {
      _showSnack('Hãy đặt cược trước! 🎲');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.rolling;
      _totalBet = _totalBetAmount;
    });

    _shakeCtrl.forward(from: 0);

    // Animation lắc: đổi ngẫu nhiên nhiều lần
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() {
        _dice = List.generate(3, (_) => _allSymbols[_rng.nextInt(6)]);
      });
    }

    // Kết quả cuối
    final finalDice = List.generate(3, (_) => _allSymbols[_rng.nextInt(6)]);
    if (!mounted) return;
    setState(() => _dice = finalDice);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Tính thắng/thua
    // Mỗi xúc xắc trúng ô đặt → thắng 1x tiền cược ô đó
    int win = 0;
    for (final entry in _bets.entries) {
      final sym = entry.key;
      final bet = entry.value;
      final matchCount = finalDice.where((d) => d == sym).length;
      if (matchCount > 0) {
        win += bet * (matchCount + 1); // trả vốn + lãi
      }
      // Nếu matchCount == 0 → mất cược (đã trừ khi đặt)
    }

    final netWin = win - _totalBet; // lãi ròng (có thể âm)

    setState(() {
      _coins += win;
      _lastWin = netWin;
      _phase = _Phase.result;
      if (netWin > 0) {
        _wins++;
      } else {
        _losses++;
      }
      _history.insert(0, {
        'dice': List<BauCuaSymbol>.from(finalDice),
        'bets': Map<BauCuaSymbol, int>.from(_bets),
        'net': netWin,
      });
      if (_history.length > 5) _history.removeLast();
    });

    _resultCtrl.forward(from: 0);
    if (netWin > 0) HapticFeedback.heavyImpact();
  }

  void _nextRound() {
    setState(() {
      _bets.clear();
      _phase = _Phase.betting;
      _lastWin = 0;
      _totalBet = 0;
    });
    _resultCtrl.reset();
  }

  void _resetGame() {
    setState(() {
      _coins = 1000;
      _bets.clear();
      _phase = _Phase.betting;
      _lastWin = 0;
      _totalBet = 0;
      _wins = 0;
      _losses = 0;
      _history.clear();
      _dice = [BauCuaSymbol.bau, BauCuaSymbol.cua, BauCuaSymbol.tom];
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B0000), // đỏ đậm đặc trưng Tết
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    // ── Bàn cược 6 ô ─────────────────────────────────────
                    _buildBettingBoard(),

                    const SizedBox(height: 16),

                    // ── Khu vực 3 xúc xắc ────────────────────────────────
                    _buildDiceArea(),

                    const SizedBox(height: 16),

                    // ── Kết quả ──────────────────────────────────────────
                    if (_phase == _Phase.result) _buildResultCard(),

                    if (_phase == _Phase.result) const SizedBox(height: 12),

                    // ── Điều khiển cược + nút Lắc ────────────────────────
                    _buildControls(),

                    const SizedBox(height: 16),

                    // ── Lịch sử ──────────────────────────────────────────
                    if (_history.isNotEmpty) _buildHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Navigator.canPop(context)
              ? GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                )
              : const SizedBox(width: 40),
          const Spacer(),
          Column(
            children: [
              Text(
                '🎲 BẦU CUA TÔM CÁ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Chúc mừng năm mới! 🧧',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: const Color(0xFFFFD700).withOpacity(0.9),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Xu + stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$_coins',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🏆$_wins',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '💀$_losses',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bàn cược 6 ô ─────────────────────────────────────────────────────────
  Widget _buildBettingBoard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B0000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tiêu đề bàn
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ĐẶT CƯỢC',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 2,
                  ),
                ),
                if (_totalBetAmount > 0)
                  GestureDetector(
                    onTap: _clearAllBets,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Xoá tất cả',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 6 ô bầu cua — 2 hàng x 3 ô
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: _allSymbols
                  .map(
                    (sym) => _BettingCell(
                      symbol: sym,
                      bet: _bets[sym] ?? 0,
                      isWinner: _phase == _Phase.result && _dice.contains(sym),
                      isRolling: _phase == _Phase.rolling,
                      canBet: _phase == _Phase.betting,
                      onTap: () => _placeBet(sym),
                      onLongPress: () => _clearBet(sym),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Khu vực xúc xắc ──────────────────────────────────────────────────────
  Widget _buildDiceArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5C0000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            '3 XÚC XẮC',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFD700).withOpacity(0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Xúc xắc
          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final shake =
                  sin(_shakeCtrl.value * pi * 12) *
                  (_phase == _Phase.rolling ? 10.0 : 0.0);
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _dice.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _DiceWidget(
                    symbol: e.value,
                    isRolling: _phase == _Phase.rolling,
                    glowCtrl: _glowCtrl,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Chú thích kết quả xúc xắc
          if (_phase == _Phase.result)
            Wrap(
              spacing: 8,
              children: _dice.toSet().map((sym) {
                final count = _dice.where((d) => d == sym).length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sym.color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sym.color.withOpacity(0.6)),
                  ),
                  child: Text(
                    '${sym.emoji} ${sym.label}${count > 1 ? ' x$count' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ── Kết quả ──────────────────────────────────────────────────────────────
  Widget _buildResultCard() {
    final isWin = _lastWin > 0;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isWin
              ? const Color(0xFFFFD700).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWin
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Text(
              isWin ? '🎉 THẮNG!' : '😔 THUA!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isWin
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            if (isWin)
              Text(
                '+$_lastWin xu 🪙',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFD700),
                ),
              )
            else
              Text(
                '$_lastWin xu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              isWin
                  ? 'Lộc đầu năm! Chúc mừng 🧧'
                  : 'Thử lại, may mắn sẽ đến! 🎋',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            if (_coins <= 0) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _resetGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nạp thêm xu (reset)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B0000),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  Widget _buildControls() {
    return Column(
      children: [
        // Mệnh giá đặt cược
        if (_phase == _Phase.betting) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mệnh giá:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              ...[10, 50, 100, 200].map(
                (amt) => GestureDetector(
                  onTap: () => setState(() => _betAmount = amt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _betAmount == amt
                          ? const Color(0xFFFFD700)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _betAmount == amt
                            ? const Color(0xFFFFD700)
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '$amt',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _betAmount == amt
                            ? const Color(0xFF8B0000)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Nút chính
        if (_phase == _Phase.result)
          GestureDetector(
            onTap: _nextRound,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                '🔄  Ván tiếp theo',
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
            onTap: _phase == _Phase.betting ? _roll : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: _bets.isNotEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      )
                    : null,
                color: _bets.isEmpty ? Colors.white.withOpacity(0.08) : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _bets.isNotEmpty
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.35),
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
                    _phase == _Phase.rolling ? '🎲' : '🎲',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _phase == _Phase.rolling
                        ? 'Đang lắc...'
                        : _bets.isEmpty
                        ? 'Chọn ô để đặt cược'
                        : 'LẮC (cược: $_totalBetAmount xu)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _bets.isNotEmpty
                          ? const Color(0xFF8B0000)
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Lịch sử ──────────────────────────────────────────────────────────────
  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📜 Lịch sử gần đây',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        ..._history.map((h) {
          final dice = h['dice'] as List<BauCuaSymbol>;
          final net = h['net'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                // 3 xúc xắc mini
                ...dice.map(
                  (s) => Text(s.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dice.map((s) => s.label).join(' · '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                Text(
                  net > 0 ? '+$net 🪙' : '$net 🪙',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: net > 0
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Betting Cell ──────────────────────────────────────────────────────────────
class _BettingCell extends StatelessWidget {
  final BauCuaSymbol symbol;
  final int bet;
  final bool isWinner;
  final bool isRolling;
  final bool canBet;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BettingCell({
    required this.symbol,
    required this.bet,
    required this.isWinner,
    required this.isRolling,
    required this.canBet,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canBet ? onTap : null,
      onLongPress: canBet ? onLongPress : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinner
              ? symbol.color.withOpacity(0.35)
              : bet > 0
              ? symbol.color.withOpacity(0.2)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWinner
                ? symbol.color
                : bet > 0
                ? symbol.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: isWinner ? 2.5 : 1.5,
          ),
          boxShadow: isWinner
              ? [
                  BoxShadow(
                    color: symbol.color.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  symbol.emoji,
                  style: TextStyle(fontSize: isWinner ? 30 : 26),
                ),
                const SizedBox(height: 2),
                Text(
                  symbol.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isWinner
                        ? Colors.white
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),

            // Hiển thị số xu cược
            if (bet > 0)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$bet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B0000),
                    ),
                  ),
                ),
              ),

            // Checkmark khi thắng
            if (isWinner)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: symbol.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
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
  final BauCuaSymbol symbol;
  final bool isRolling;
  final AnimationController glowCtrl;

  const _DiceWidget({
    required this.symbol,
    required this.isRolling,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (_, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isRolling
              ? const Color(0xFF3D0000)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRolling
                ? const Color(
                    0xFFFFD700,
                  ).withOpacity(0.4 + glowCtrl.value * 0.4)
                : const Color(0xFFFFD700).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isRolling
                  ? const Color(
                      0xFFFFD700,
                    ).withOpacity(0.2 + glowCtrl.value * 0.2)
                  : Colors.black.withOpacity(0.3),
              blurRadius: isRolling ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            symbol.emoji,
            style: TextStyle(fontSize: isRolling ? 28 : 36),
          ),
        ),
      ),
    );
  }
}
