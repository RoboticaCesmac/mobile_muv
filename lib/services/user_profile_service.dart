import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'token_manager.dart';
import '../config/environment_config.dart';

class UserProfileService {
  String get baseUrl => EnvironmentConfig.baseUrl;

  Future<UserProfile?> getUserProfile() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.getAuthHeader(),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Falha ao buscar perfil: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }
} 