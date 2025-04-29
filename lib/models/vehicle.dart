class Vehicle {
  final int id;
  final String name;
  final double co2PerKm;
  final String iconPath;
  final int pointsPerKm;
  final String createdAt;
  final String updatedAt;
  final String iconUrl;

  Vehicle({
    required this.id,
    required this.name,
    required this.co2PerKm,
    required this.iconPath,
    required this.pointsPerKm,
    required this.createdAt,
    required this.updatedAt,
    required this.iconUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      name: json['name'],
      co2PerKm: double.parse(json['co2_per_km'].toString()),
      iconPath: json['icon_path'],
      pointsPerKm: json['points_per_km'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      iconUrl: json['icon_url'],
    );
  }
} 