class UserProfile {
  final int id;
  final String userName;
  final String email;
  final String gender;
  final DateTime dateOfBirth;
  final num? totalPoints;
  final num? totalKm;
  final bool isFirstLogin;
  final Vehicle vehicle;
  final Avatar avatar;
  final ProfileData profileData;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userName,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    this.totalPoints,
    this.totalKm,
    required this.isFirstLogin,
    required this.vehicle,
    required this.avatar,
    required this.profileData,
    required this.createdAt,
    required this.updatedAt,
  });

  // Função auxiliar para converter valores para num, sejam eles numéricos ou strings
  static num? toNumOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userName: json['user_name'],
      email: json['email'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      totalPoints: toNumOrNull(json['total_points']),
      totalKm: toNumOrNull(json['total_km']),
      isFirstLogin: json['is_first_login'],
      vehicle: Vehicle.fromJson(json['vehicle']),
      avatar: Avatar.fromJson(json['avatar']),
      profileData: ProfileData.fromJson(json['perfil_data']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Vehicle {
  final int id;
  final String name;
  final num co2PerKm;
  final String iconPath;
  final num pointsPerKm;
  final DateTime createdAt;
  final DateTime updatedAt;
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      iconUrl: json['icon_url'],
    );
  }
}

class Avatar {
  final int id;
  final String name;
  final String avatarPath;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String avatarUrl;

  Avatar({
    required this.id,
    required this.name,
    required this.avatarPath,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    required this.avatarUrl,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatar_path'],
      isDefault: json['is_default'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      avatarUrl: json['avatar_url'],
    );
  }
}

class ProfileData {
  final num currentLevel;
  final num carbonFootprintToNextLevel;
  final num totalPoints;
  final num totalPointsOfNextLevel;
  final num distanceTraveled;
  final num totalCarbonFootprint;
  final num totalCarbonFootprintOfNextLevel;
  final String? currentLevelUrl;

  ProfileData({
    required this.currentLevel,
    required this.carbonFootprintToNextLevel,
    required this.totalPoints,
    required this.totalPointsOfNextLevel,
    required this.distanceTraveled,
    required this.totalCarbonFootprint,
    required this.totalCarbonFootprintOfNextLevel,
    this.currentLevelUrl,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    // Função auxiliar para converter qualquer valor para num de forma segura
    num toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return ProfileData(
      currentLevel: toNum(json['current_level'] ?? 1),
      carbonFootprintToNextLevel: toNum(json['carbon_footprint_to_next_level']),
      totalPoints: toNum(json['total_points']),
      totalPointsOfNextLevel: toNum(json['total_points_of_next_level'] ?? 100),
      distanceTraveled: toNum(json['distance_traveled']),
      totalCarbonFootprint: toNum(json['total_carbon_footprint']),
      totalCarbonFootprintOfNextLevel: toNum(json['total_carbon_footprint_of_next_level']),
      currentLevelUrl: json['current_level_url'],
    );
  }
} 