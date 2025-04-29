class UserProfile {
  final int id;
  final String userName;
  final String email;
  final String gender;
  final DateTime dateOfBirth;
  final int? totalPoints;
  final double? totalKm;
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

  // Função auxiliar para converter valores para double, sejam eles numéricos ou strings
  static double? toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userName: json['user_name'],
      email: json['email'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      totalPoints: json['total_points'],
      totalKm: toDoubleOrNull(json['total_km']),
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
  final double co2PerKm;
  final String iconPath;
  final int pointsPerKm;
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
    return Vehicle(
      id: json['id'],
      name: json['name'],
      co2PerKm: UserProfile.toDoubleOrNull(json['co2_per_km']) ?? 0.0,
      iconPath: json['icon_path'],
      pointsPerKm: json['points_per_km'],
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
  final int currentLevel;
  final int pointToNextLevel;
  final int totalPoints;
  final int totalPointsOfNextLevel;
  final double distanceTraveled;
  final String? currentLevelIcon;

  ProfileData({
    required this.currentLevel,
    required this.pointToNextLevel,
    required this.totalPoints,
    required this.totalPointsOfNextLevel,
    required this.distanceTraveled,
    this.currentLevelIcon,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      currentLevel: json['current_level'],
      pointToNextLevel: json['point_to_next_level'],
      totalPoints: json['total_points'],
      totalPointsOfNextLevel: json['total_points_of_next_level'],
      distanceTraveled: UserProfile.toDoubleOrNull(json['distance_traveled']) ?? 0.0,
      currentLevelIcon: json['current_level_icon'],
    );
  }
} 