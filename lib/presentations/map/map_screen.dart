import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);

  int _categoryIndex = 0;
  _Place? _selectedPlace;

  // ── Về quê state ─────────────────────────────────────────────────
  bool _locating = false;
  final _originCtrl = TextEditingController(text: 'Hà Nội');
  final _destCtrl = TextEditingController();

  // ── Dữ liệu ──────────────────────────────────────────────────────
  static const _categories = [
    _Cat(icon: Icons.local_florist_rounded, label: 'Vườn hoa'),
    _Cat(icon: Icons.temple_buddhist_rounded, label: 'Chùa'),
    _Cat(icon: Icons.festival_rounded, label: 'Lễ hội'),
    _Cat(icon: Icons.account_balance_rounded, label: 'Di tích'),
  ];

  static const _places = [
    // Vườn hoa
    _Place(
      name: 'Vườn Đào Nhật Tân',
      district: 'Tây Hồ, Hà Nội',
      category: 0,
      checkins: 1240,
      lat: 21.0799,
      lng: 105.8412,
    ),
    _Place(
      name: 'Chợ Hoa Quảng An',
      district: 'Tây Hồ, Hà Nội',
      category: 0,
      checkins: 890,
      lat: 21.0688,
      lng: 105.8260,
    ),
    _Place(
      name: 'Công viên Thống Nhất',
      district: 'Hai Bà Trưng, HN',
      category: 0,
      checkins: 560,
      lat: 21.0139,
      lng: 105.8456,
    ),
    _Place(
      name: 'Vườn hoa Lý Thái Tổ',
      district: 'Hoàn Kiếm, HN',
      category: 0,
      checkins: 720,
      lat: 21.0289,
      lng: 105.8520,
    ),
    // Chùa
    _Place(
      name: 'Chùa Trấn Quốc',
      district: 'Tây Hồ, Hà Nội',
      category: 1,
      checkins: 2100,
      lat: 21.0456,
      lng: 105.8360,
    ),
    _Place(
      name: 'Chùa Hương',
      district: 'Mỹ Đức, Hà Nội',
      category: 1,
      checkins: 3500,
      lat: 20.6167,
      lng: 105.7333,
    ),
    _Place(
      name: 'Chùa Một Cột',
      district: 'Ba Đình, Hà Nội',
      category: 1,
      checkins: 1800,
      lat: 21.0356,
      lng: 105.8340,
    ),
    // Lễ hội
    _Place(
      name: 'Hội Gióng Phù Đổng',
      district: 'Gia Lâm, Hà Nội',
      category: 2,
      checkins: 980,
      lat: 21.0689,
      lng: 105.9456,
    ),
    _Place(
      name: 'Lễ hội Đống Đa',
      district: 'Đống Đa, Hà Nội',
      category: 2,
      checkins: 1100,
      lat: 21.0230,
      lng: 105.8430,
    ),
    // Di tích
    _Place(
      name: 'Văn Miếu Quốc Tử Giám',
      district: 'Đống Đa, HN',
      category: 3,
      checkins: 2300,
      lat: 21.0275,
      lng: 105.8355,
    ),
    _Place(
      name: 'Hoàng Thành Thăng Long',
      district: 'Ba Đình, HN',
      category: 3,
      checkins: 1650,
      lat: 21.0360,
      lng: 105.8352,
    ),
  ];

  static const _hotRoutes = [
    _Route(label: 'HN → TP.HCM', origin: 'Hà Nội', dest: 'Hồ Chí Minh'),
    _Route(label: 'HN → Đà Nẵng', origin: 'Hà Nội', dest: 'Đà Nẵng'),
    _Route(label: 'HN → Hải Phòng', origin: 'Hà Nội', dest: 'Hải Phòng'),
    _Route(label: 'HN → Nam Định', origin: 'Hà Nội', dest: 'Nam Định'),
    _Route(label: 'HN → Nghệ An', origin: 'Hà Nội', dest: 'Nghệ An'),
    _Route(label: 'HCM → Cần Thơ', origin: 'Hồ Chí Minh', dest: 'Cần Thơ'),
  ];

  List<_Place> get _filtered =>
      _places.where((p) => p.category == _categoryIndex).toList();

  @override
  void dispose() {
    _tabCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  // ── GPS ───────────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Vui lòng bật GPS trên thiết bị');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showSnack('Cần cấp quyền truy cập vị trí');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Vào Cài đặt → Ứng dụng để cấp quyền vị trí');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _originCtrl.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
      _showSnack('Đã lấy vị trí hiện tại ✓');
    } catch (e) {
      _showSnack('Không lấy được vị trí: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ── Chỉ đường ─────────────────────────────────────────────────────
  Future<void> _openDirections(String origin, String dest) async {
    if (dest.trim().isEmpty) {
      _showSnack('Vui lòng nhập điểm đến');
      return;
    }

    final destEnc = Uri.encodeComponent(dest);
    final originEnc = Uri.encodeComponent(origin);

    // Thử mở Google Maps app
    final gmapsApp = Uri.parse('google.navigation:q=$destEnc&mode=d');
    // Fallback: mở Google Maps trên browser
    final gmapsWeb = Uri.parse(
      'https://www.google.com/maps/dir/$originEnc/$destEnc',
    );

    try {
      if (await canLaunchUrl(gmapsApp)) {
        await launchUrl(gmapsApp);
      } else {
        await launchUrl(gmapsWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showSnack('Không thể mở bản đồ chỉ đường');
    }
  }

  // Chỉ đường đến địa điểm trên map
  Future<void> _directionsToPlace(_Place place) async {
    final dest = Uri.encodeComponent(place.name);
    final gmapsApp = Uri.parse('google.navigation:q=$dest&mode=d');
    final gmapsWeb = Uri.parse(
      'https://www.google.com/maps/search/${Uri.encodeComponent(place.name)}',
    );
    try {
      if (await canLaunchUrl(gmapsApp)) {
        await launchUrl(gmapsApp);
      } else {
        await launchUrl(gmapsWeb, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _showSnack('Không thể mở chỉ đường');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _catColor(int i) {
    const colors = [
      AppColors.primary,
      Color(0xFFF9A825), // amber
      Color(0xFF8E24AA), // purple
      Color(0xFF00897B), // teal
    ];
    return colors[i % colors.length];
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: [
                  Text(
                    'DU XUÂN PLANNER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bản đồ Du Xuân',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brownDeep,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: '🗺️  Điểm đến Tết'),
                  Tab(text: '🏡  Về quê'),
                ],
              ),
            ),

            // ── Tab views ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [_buildMapTab(), _buildHomeTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Tab 1: Bản đồ OSM + markers
  // ──────────────────────────────────────────────────────────────────
  Widget _buildMapTab() {
    final filtered = _filtered;
    final color = _catColor(_categoryIndex);

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final isActive = i == _categoryIndex;
              return GestureDetector(
                onTap: () => setState(() {
                  _categoryIndex = i;
                  _selectedPlace = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _categories[i].icon,
                        size: 14,
                        color: isActive ? Colors.white : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _categories[i].label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Bản đồ OSM
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(21.0285, 105.8542),
                  initialZoom: 12,
                  onTap: (_, __) => setState(() => _selectedPlace = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vivu.tet',
                  ),
                  MarkerLayer(
                    markers: filtered.map((p) {
                      final isSelected = _selectedPlace == p;
                      return Marker(
                        point: LatLng(p.lat, p.lng),
                        width: isSelected ? 130 : 40,
                        height: isSelected ? 72 : 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlace = p),
                          child: _MapMarker(
                            place: p,
                            isSelected: isSelected,
                            color: color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Place card bottom
              if (_selectedPlace != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _PlaceCard(
                    place: _selectedPlace!,
                    color: color,
                    onClose: () => setState(() => _selectedPlace = null),
                    onDirections: () => _directionsToPlace(_selectedPlace!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Tab 2: Về quê
  // ──────────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form chỉ đường
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Điểm xuất phát + GPS ────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _originCtrl,
                        decoration: InputDecoration(
                          hintText: 'Điểm xuất phát',
                          filled: true,
                          fillColor: AppColors.warmCream,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          // Nút GPS
                          suffixIcon: _locating
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.gps_fixed_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'Lấy vị trí hiện tại',
                                  onPressed: _getLocation,
                                ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // Đường chấm nối
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 2,
                        height: 6,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),

                // ── Điểm đến ────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _destCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nhập quê / điểm đến',
                          filled: true,
                          fillColor: AppColors.warmCream,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Nút chỉ đường ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openDirections(_originCtrl.text, _destCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Mở Google Maps chỉ đường',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Tuyến hot ─────────────────────────────────────
          Text(
            'Tuyến đường phổ biến',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.brownDeep,
            ),
          ),
          const SizedBox(height: 12),

          ..._hotRoutes.map(
            (r) => GestureDetector(
              onTap: () => _openDirections(r.origin, r.dest),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brownDeep,
                            ),
                          ),
                          Text(
                            '${r.origin} → ${r.dest}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Tips ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.07),
                  Colors.orange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Mẹo về quê ngày Tết',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brownDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  '🚗  Tránh khởi hành ngày 27–28 Tết, đường rất đông',
                  '⏰  Nên đi sớm trước 6h sáng hoặc sau 20h tối',
                  '⛽  Đổ đầy xăng trước khi lên đường',
                  '📱  Tải bản đồ offline phòng mất sóng vùng núi',
                  '🎒  Chuẩn bị đồ ăn nhẹ cho hành trình dài',
                ].map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      tip,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.brownMid,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Marker ────────────────────────────────────────────────────────────────
class _MapMarker extends StatelessWidget {
  final _Place place;
  final bool isSelected;
  final Color color;
  const _MapMarker({
    required this.place,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
              ],
            ),
            child: Text(
              place.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 12),
              ],
            ),
            child: const Icon(
              Icons.place_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
      ),
      child: const Icon(Icons.place_rounded, color: Colors.white, size: 18),
    );
  }
}

// ── Place Card ────────────────────────────────────────────────────────────────
class _PlaceCard extends StatelessWidget {
  final _Place place;
  final Color color;
  final VoidCallback onClose;
  final VoidCallback onDirections;

  const _PlaceCard({
    required this.place,
    required this.color,
    required this.onClose,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.place_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDeep,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        place.district,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${place.checkins}+ lượt check-in',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              // Nút đóng
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Nút chỉ đường
              GestureDetector(
                onTap: onDirections,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _Cat {
  final IconData icon;
  final String label;
  const _Cat({required this.icon, required this.label});
}

class _Place {
  final String name, district;
  final int category, checkins;
  final double lat, lng;
  const _Place({
    required this.name,
    required this.district,
    required this.category,
    required this.checkins,
    required this.lat,
    required this.lng,
  });
}

class _Route {
  final String label, origin, dest;
  const _Route({required this.label, required this.origin, required this.dest});
}
