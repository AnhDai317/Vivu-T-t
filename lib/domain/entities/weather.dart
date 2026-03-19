class Weather {
  final double temperature;
  final String description;
  final String icon; // emoji
  final String cityName; // tên thành phố lấy từ reverse geocoding

  const Weather({
    required this.temperature,
    required this.description,
    required this.icon,
    this.cityName = 'Hà Nội', // fallback
  });
}
