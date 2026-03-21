class Weather {
  final double temperature;
  final String description;
  final String icon;
  final String cityName;
  final double? maxTemp;
  final double? minTemp;

  const Weather({
    required this.temperature,
    required this.description,
    required this.icon,
    this.cityName = 'Hà Nội',
    this.maxTemp,
    this.minTemp,
  });
}
