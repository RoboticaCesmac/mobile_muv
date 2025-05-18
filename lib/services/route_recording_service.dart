import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';
import 'route_manager.dart';

class RouteRecordingService {
  final ApiClient _apiClient = ApiClient();
  final Connectivity _connectivity = Connectivity();

  /// Inicia uma nova rota
  Future<bool> startRoute({
    required int vehicleId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Verifica conectividade
      var connectivityResult = await _connectivity.checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        final response = await _apiClient.post(
          'mobile/route/start',
          body: {
            'vehicle_id': vehicleId,
            'latitude': latitude,
            'longitude': longitude,
          },
        );

        return response.statusCode == 200;
      } else {
        // Se offline, inicia uma rota local
        await RouteManager.clearCurrentRoute(); // Garante que não haja uma rota anterior
        await RouteManager.addPointToCurrentRoute(latitude, longitude);
        return true;
      }
    } catch (e) {
      print('Erro ao iniciar rota: $e');
      // Se ocorrer um erro (possivelmente de conectividade), tenta salvar localmente
      await RouteManager.clearCurrentRoute();
      await RouteManager.addPointToCurrentRoute(latitude, longitude);
      return true;
    }
  }

  /// Adiciona um ponto à rota atual
  /// Retorna um Map com o status do envio e se foi salvo localmente
  Future<Map<String, dynamic>> addRoutePoint({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    try {
      // Verifica conectividade
      var connectivityResult = await _connectivity.checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        final Map<String, dynamic> body = { 
          'latitude': latitude,
          'longitude': longitude,
        };

        // Adiciona o timestamp apenas se for fornecido
        if (timestamp != null) {
          body['created_at'] = timestamp.toLocal().toString().substring(0, 19).replaceAll('T', ' ');
        }

        final response = await _apiClient.post(
          'mobile/route/points',
          body: body,
        );

        return {
          'success': response.statusCode == 200,
          'savedLocally': false
        };
      } else {
        // Se estiver offline, salva localmente
        await RouteManager.addPointToCurrentRoute(latitude, longitude);
        return {
          'success': true,
          'savedLocally': true
        };
      }
    } catch (e) {
      print('Erro ao adicionar ponto à rota: $e');
      // Se ocorrer um erro (possivelmente de conectividade), salva localmente
      await RouteManager.addPointToCurrentRoute(latitude, longitude);
      return {
        'success': true,
        'savedLocally': true
      };
    }
  }

  /// Finaliza a rota atual
  Future<bool> finishRoute({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Verifica conectividade
      var connectivityResult = await _connectivity.checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
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
      } else {
        // Se estiver offline, adiciona último ponto e finaliza rota local
        await RouteManager.addPointToCurrentRoute(latitude, longitude);
        await RouteManager.finishCurrentRoute();
        return true;
      }
    } catch (e) {
      print('Erro ao finalizar rota: $e');
      // Se ocorrer um erro, finaliza localmente
      try {
        await RouteManager.addPointToCurrentRoute(latitude, longitude);
        await RouteManager.finishCurrentRoute();
      } catch (e) {
        print('Erro ao finalizar localmente: $e');
      }
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
  
  /// Sincroniza rotas offline completas
  /// [onPointSync] - Callback chamado para cada ponto sincronizado (sucesso ou falha)
  /// [onRouteComplete] - Callback chamado quando uma rota completa é sincronizada
  Future<bool> syncOfflineRoutes({
    Function(bool success, int routeIndex, int pointIndex, int totalPoints)? onPointSync,
    Function(bool success, int routeIndex)? onRouteComplete,
  }) async {
    try {
      // Obter rotas offline
      final offlineRoutes = await RouteManager.getOfflineRoutes();
      
      if (offlineRoutes.isEmpty) {
        print('Nenhuma rota offline para sincronizar');
        return true; // Nada para sincronizar
      }
      
      print('Sincronizando ${offlineRoutes.length} rotas offline');
      bool allRoutesSuccess = true;
      
      // Tenta enviar cada rota offline
      for (var i = 0; i < offlineRoutes.length; i++) {
        final route = offlineRoutes[i];
        bool routeSendSuccess = true;
        
        print('Sincronizando rota $i com ${route.length} pontos');
        
        // Envia os pontos dessa rota offline
        for (var j = 0; j < route.length; j++) {
          final point = route[j];
          try {
            print('Enviando ponto $j/${route.length} da rota $i: ${point.latitude}, ${point.longitude}');
            
            final result = await addRoutePoint(
              latitude: point.latitude,
              longitude: point.longitude,
              timestamp: point.timestamp,
            );
            
            bool pointSuccess = result['success'] == true;
            
            // Notifica a UI sobre o status do ponto
            onPointSync?.call(pointSuccess, i, j, route.length);
            
            if (!pointSuccess) {
              routeSendSuccess = false;
              allRoutesSuccess = false;
              print('Falha ao enviar ponto de rota offline');
              break;
            }
          } catch (e) {
            routeSendSuccess = false;
            allRoutesSuccess = false;
            // Notifica a UI sobre a falha
            onPointSync?.call(false, i, j, route.length);
            print('Erro ao sincronizar ponto de rota offline: $e');
            break;
          }
        }
        
        // Se todos os pontos foram enviados com sucesso, finaliza a rota
        if (routeSendSuccess && route.isNotEmpty) {
          final lastPoint = route.last;
          try {
            print('Finalizando rota $i com ponto final: ${lastPoint.latitude}, ${lastPoint.longitude}');
            
            final routeFinished = await finishRoute(
              latitude: lastPoint.latitude,
              longitude: lastPoint.longitude,
            );
            
            if (routeFinished) {
              // Remove a rota offline após o envio bem-sucedido
              await RouteManager.removeOfflineRoute(i);
              print('Rota offline #$i sincronizada e removida com sucesso');
              
              // Notifica a UI que a rota foi completamente sincronizada
              onRouteComplete?.call(true, i);
            } else {
              allRoutesSuccess = false;
              onRouteComplete?.call(false, i);
              print('Falha ao finalizar rota $i');
            }
          } catch (e) {
            allRoutesSuccess = false;
            print('Erro ao finalizar rota offline #$i: $e');
            onRouteComplete?.call(false, i);
          }
        } else {
          allRoutesSuccess = false;
          onRouteComplete?.call(false, i);
          print('Não foi possível finalizar a rota $i porque nem todos os pontos foram enviados');
        }
      }
      
      return allRoutesSuccess;
    } catch (e) {
      print('Erro ao sincronizar rotas offline: $e');
      return false;
    }
  }
} 