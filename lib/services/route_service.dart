import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_data.dart';
import 'token_manager.dart';
import '../config/environment_config.dart';

class RouteService {
  String get baseUrl => EnvironmentConfig.baseUrl;

  Future<List<RouteData>> getRoutes({int page = 1}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.getAuthHeader(),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/mobile/route?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data.containsKey('data') && data['data'] is List) {
          final routes = data['data'] as List;
          
          for (var i = 0; i < routes.length; i++) {
            var route = routes[i];
            
            if (route['vehicle'] != null) {
              var vehicle = route['vehicle'];
            }
            
            if (route['route_points'] != null && route['route_points'] is List) {
            }
          }
        }
        
        List<RouteData> routeList = (data['data'] as List)
            .map((routeJson) => RouteData.fromJson(routeJson))
            .toList();
            
        return routeList;
      } else {
        throw Exception('Failed to fetch routes: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }
} 