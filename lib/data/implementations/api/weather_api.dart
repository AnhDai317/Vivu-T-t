import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vivu_tet/domain/entities/weather.dart';

class WeatherApi {
  // Lấy thời tiết theo lat/lng — mặc định Hà Nội
  Future<Weather> getCurrentWeather({
    double lat = 21.0285,
    double lng = 105.8542,
  }) async {
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
    );
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
