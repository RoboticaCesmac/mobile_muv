class Vehicle {
  final int id;
  final String name;
  final num co2PerKm;
  final String iconPath;
  final num pointsPerKm;
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
    // Função auxiliar para converter qualquer valor para num de forma segura
    num toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return Vehicle(
      id: json['id'],
      name: json['name'],
      co2PerKm: toNum(json['co2_per_km']),
      iconPath: json['icon_path'],
      pointsPerKm: toNum(json['points_per_km']),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      iconUrl: json['icon_url'],
    );
  }
} 