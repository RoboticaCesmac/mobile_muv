import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_avatar.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class AvatarService {
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

  Future<bool> updateUserAvatar(int avatarId) async {
    try {
      final response = await _apiClient.patch(
        'mobile/user/user-avatar',
        body: {
          'avatar_id': avatarId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar avatar: $e');
    }
  }
} 