import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class RouteRecordingService {
  final ApiClient _apiClient = ApiClient();

  /// Inicia uma nova rota
  Future<bool> startRoute({
    required int vehicleId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        'mobile/route/start',
        body: {
          'vehicle_id': vehicleId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao iniciar rota: $e');
      return false;
    }
  }

  /// Adiciona um ponto à rota atual
  Future<bool> addRoutePoint({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        'mobile/route/points',
        body: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao adicionar ponto à rota: $e');
      return false;
    }
  }

  /// Finaliza a rota atual
  Future<bool> finishRoute({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        'mobile/route/finish',
        body: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      print('----------------------------------');
      print('Resposta de finalização de rota - Status: ${response.statusCode}');
      print('----------------------------------');
      print(response.body);
      print('----------------------------------');
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao finalizar rota: $e');
      return false;
    }
  }

  /// Verifica o status da rota
  Future<Map<String, dynamic>> getRouteStatus() async {
    try {
      print('----------------------------------');
      print('Verificando status da rota atual');
      print('----------------------------------');
      final response = await _apiClient.get('mobile/route/route-screen');
      
      print('----------------------------------');
      print('Resposta de status da rota - Status: ${response.statusCode}');
      print('----------------------------------');
      print(response.body);
      print('----------------------------------');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['data'] ?? {};
      }
      
      print('Status da rota não retornou 200: ${response.statusCode}');
      return {};
    } catch (e) {
      print('----------------------------------');
      print('Erro ao verificar status da rota: $e');
      print('----------------------------------');
      return {};
    }
  }
} 