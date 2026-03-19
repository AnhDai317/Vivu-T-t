import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:vivu_tet/domain/entities/weather.dart';

class WeatherApi {
  /// Lấy thời tiết theo vị trí GPS hiện tại.
  /// Nếu không lấy được GPS → fallback về Hà Nội.
  Future<Weather> getCurrentWeather() async {
    double lat = 21.0285;
    double lng = 105.8542;
    String city = 'Hà Nội';

    // --- Thử lấy vị trí GPS ---
    try {
      final pos = await _getPosition();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
        city = await _reverseGeocode(lat, lng);
      }
    } catch (_) {
      // GPS thất bại → dùng Hà Nội mặc định
    }

    // --- Gọi Open-Meteo ---
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lng'
      '&current=temperature_2m,weathercode'
      '&timezone=Asia%2FBangkok',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('Weather API error: ${res.statusCode}');
    }

    final json = jsonDecode(res.body);
    final current = json['current'];
    final temp = (current['temperature_2m'] as num).toDouble();
    final code = current['weathercode'] as int;

    return Weather(
      temperature: temp,
      description: _descFromCode(code),
      icon: _iconFromCode(code),
      cityName: city,
    );
  }

  /// Lấy GPS (kiểm tra permission, không hỏi lại nếu đã từ chối).
  Future<Position?> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low, // nhanh hơn, đủ cho thời tiết
      timeLimit: const Duration(seconds: 5),
    );
  }

  /// Reverse geocode lat/lng → tên thành phố/quận bằng Nominatim (OSM, miễn phí).
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=vi',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'ViVuTet/1.0'})
          .timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) return 'Vị trí của bạn';

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = json['address'] as Map<String, dynamic>? ?? {};

      // Ưu tiên: city → town → county → state
      return (addr['city'] ??
              addr['town'] ??
              addr['county'] ??
              addr['state'] ??
              'Vị trí của bạn')
          .toString();
    } catch (_) {
      return 'Vị trí của bạn';
    }
  }

  String _descFromCode(int code) {
    if (code == 0) return 'Trời quang';
    if (code <= 3) return 'Ít mây';
    if (code <= 48) return 'Có sương mù';
    if (code <= 57) return 'Mưa phùn';
    if (code <= 67) return 'Có mưa';
    if (code <= 77) return 'Có tuyết';
    if (code <= 82) return 'Mưa rào';
    if (code <= 99) return 'Có dông';
    return 'Không rõ';
  }

  String _iconFromCode(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 57) return '🌧️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }
}
