import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/api_client.dart';
import 'route_manager.dart';

class RouteRecordingService {
  final ApiClient _apiClient = ApiClient();
  final Connectivity _connectivity = Connectivity();

  Future<bool> startRoute({
    required int vehicleId,
    required double latitude,
    required double longitude,
  }) async {
    try {
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
        await RouteManager.clearCurrentRoute();
        await RouteManager.addPointToCurrentRoute(latitude, longitude);
        return true;
      }
    } catch (e) {
      await RouteManager.clearCurrentRoute();
      await RouteManager.addPointToCurrentRoute(latitude, longitude);
      return true;
    }
  }

  Future<Map<String, dynamic>> addRoutePoint({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      if (isOnline) {
        final Map<String, dynamic> body = { 
          'latitude': latitude,
          'longitude': longitude,
        };

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
        await RouteManager.addPointToCurrentRoute(latitude, longitude);
        return {
          'success': true,
          'savedLocally': true
        };
      }
    } catch (e) {
      await RouteManager.addPointToCurrentRoute(latitude, longitude);
      return {
        'success': true,
        'savedLocally': true
      };
    }
  }

  Future<bool> _finishRouteDirect({
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

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> finishRoute({
    required double latitude,
    required double longitude,
    Function(bool success, int routeIndex, int pointIndex, int totalPoints)? onPointSync,
    Function(bool success, int routeIndex)? onRouteComplete,
  }) async {
    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      
      await RouteManager.addPointToCurrentRoute(latitude, longitude);
      
      await RouteManager.finishCurrentRoute();
      
      if (isOnline) {
        await syncOfflineRoutes(
          onPointSync: onPointSync,
          onRouteComplete: onRouteComplete,
        );
        
        final response = await _apiClient.post(
          'mobile/route/finish',
          body: {
            'latitude': latitude,
            'longitude': longitude,
          },
        );
        return response.statusCode == 200;
      } else {
        return true;
      }
    } catch (e) {
      try {
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  Future<Map<String, dynamic>> getRouteStatus() async {
    try {
      final response = await _apiClient.get('mobile/route/route-screen');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['data'] ?? {};
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }
  
  Future<bool> syncOfflineRoutes({
    Function(bool success, int routeIndex, int pointIndex, int totalPoints)? onPointSync,
    Function(bool success, int routeIndex)? onRouteComplete,
  }) async {
    try {
      final offlineRoutes = await RouteManager.getOfflineRoutes();
      
      if (offlineRoutes.isEmpty) {
        return true;
      }
      
      bool allRoutesSuccess = true;
      
      for (var i = 0; i < offlineRoutes.length; i++) {
        final route = offlineRoutes[i];
        bool routeSendSuccess = true;
        
        
        for (var j = 0; j < route.length; j++) {
          final point = route[j];
          try {
            
            final result = await addRoutePoint(
              latitude: point.latitude,
              longitude: point.longitude,
              timestamp: point.timestamp,
            );
            
            bool pointSuccess = result['success'] == true;
            
            onPointSync?.call(pointSuccess, i, j, route.length);
            
            if (!pointSuccess) {
              routeSendSuccess = false;
              allRoutesSuccess = false;
              break;
            }
          } catch (e) {
            routeSendSuccess = false;
            allRoutesSuccess = false;
            onPointSync?.call(false, i, j, route.length);
            break;
          }
        }
        
        if (routeSendSuccess && route.isNotEmpty) {
          final lastPoint = route.last;
          try {
            
            final routeFinished = await _finishRouteDirect(
              latitude: lastPoint.latitude,
              longitude: lastPoint.longitude,
            );
            
            if (routeFinished) {
              await RouteManager.removeOfflineRoute(i);              
              onRouteComplete?.call(true, i);
            } else {
              allRoutesSuccess = false;
              onRouteComplete?.call(false, i);
            }
          } catch (e) {
            allRoutesSuccess = false;
            onRouteComplete?.call(false, i);
          }
        } else {
          allRoutesSuccess = false;
          onRouteComplete?.call(false, i);
        }
      }
      
      return allRoutesSuccess;
    } catch (e) {
      return false;
    }
  }
} 