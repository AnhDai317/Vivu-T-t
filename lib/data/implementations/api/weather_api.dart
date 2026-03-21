import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:vivu_tet/domain/entities/weather.dart';

class WeatherApi {
  double? _cachedLat;
  double? _cachedLng;
  String _cachedCity = 'Hà Nội';

  /// Thời tiết hiện tại (có GPS + reverse geocoding)
  Future<Weather> getCurrentWeather() async {
    await _resolveLocation();
    return _fetchWeatherAt(_cachedLat!, _cachedLng!, _cachedCity);
  }

  /// Dự báo thời tiết cho một ngày cụ thể (dùng trong TripDetail)
  /// Trả về null nếu ngày đó nằm ngoài 16 ngày tới
  Future<Weather?> getForecastForDate(DateTime date) async {
    await _resolveLocation();
    final today = DateTime.now();
    final diff = date
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff < 0 || diff > 15) return null; // ngoài range forecast

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${_cachedLat!}&longitude=${_cachedLng!}'
        '&daily=weathercode,temperature_2m_max,temperature_2m_min'
        '&timezone=Asia%2FBangkok'
        '&forecast_days=16',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      final daily = json['daily'];
      final dates = daily['time'] as List;
      final codes = daily['weathercode'] as List;
      final maxTemps = daily['temperature_2m_max'] as List;
      final minTemps = daily['temperature_2m_min'] as List;

      final targetStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final idx = dates.indexOf(targetStr);
      if (idx < 0) return null;

      final code = codes[idx] as int;
      final maxT = (maxTemps[idx] as num).toDouble();
      final minT = (minTemps[idx] as num).toDouble();
      final avgT = (maxT + minT) / 2;

      return Weather(
        temperature: avgT,
        description: _descFromCode(code),
        icon: _iconFromCode(code),
        cityName: _cachedCity,
        maxTemp: maxT,
        minTemp: minT,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _resolveLocation() async {
    if (_cachedLat != null) return; // đã có cache
    _cachedLat = 21.0285;
    _cachedLng = 105.8542;
    _cachedCity = 'Hà Nội';

    try {
      final pos = await _getPosition();
      if (pos != null) {
        _cachedLat = pos.latitude;
        _cachedLng = pos.longitude;
        _cachedCity = await _reverseGeocode(pos.latitude, pos.longitude);
      }
    } catch (_) {}
  }

  Future<Weather> _fetchWeatherAt(double lat, double lng, String city) async {
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
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 5),
    );
  }

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
