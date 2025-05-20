import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_avatar.dart';
import 'api_client.dart';
import 'token_manager.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UserAvatar>> getUserAvatars() async {
    try {
      final response = await _apiClient.get('mobile/avatar/all');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> avatarsData = responseData['data'];
        
        return avatarsData.map((avatarData) => UserAvatar.fromJson(avatarData)).toList();
      } else {
        throw Exception('Falha ao buscar avatares: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar avatares: $e');
    }
  }

  Future<bool> completeFirstLogin({
    required String userName,
    required String gender,
    required String dateOfBirth,
    required int vehicleId,
    required int avatarId,
  }) async {
    try {
      final response = await _apiClient.post(
        'mobile/user/first-login',
        body: {
          'user_name': userName,
          'gender': gender,
          'date_of_birth': dateOfBirth,
          'vehicle_id': vehicleId,
          'avatar_id': avatarId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao completar o primeiro login: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('mobile/auth/logout');
      await TokenManager.clearToken();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final response = await _apiClient.delete('mobile/user');
      if (response.statusCode != 200) {
        throw Exception('Falha ao excluir conta: ${response.statusCode}');
      }
      await TokenManager.clearToken();
    } catch (e) {
      throw Exception('Erro ao excluir conta: $e');
    }
  }
} 