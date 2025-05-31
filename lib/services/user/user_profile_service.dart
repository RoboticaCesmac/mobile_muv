import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_profile.dart';
import '../auth/token_manager.dart';
import '../../config/environment_config.dart';

class UserProfileService {
  String get baseUrl => EnvironmentConfig.baseUrl;

  Future<UserProfile?> getUserProfile({String? period}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.getAuthHeader(),
      };

      // Construir a URL com o parâmetro period se fornecido
      String url = '$baseUrl/auth/me';
      if (period != null) {
        url += '?period=$period';
      }

      final response = await http.get(
        Uri.parse(url),
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