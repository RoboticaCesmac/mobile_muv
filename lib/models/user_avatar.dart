class UserAvatar {
  final int id;
  final String name;
  final String avatarPath;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;
  final String avatarUrl;

  UserAvatar({
    required this.id,
    required this.name,
    required this.avatarPath,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    required this.avatarUrl,
  });

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      id: json['id'],
      name: json['name'],
      avatarPath: json['avatar_path'],
      isDefault: json['is_default'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      avatarUrl: json['avatar_url'],
    );
  }
} 