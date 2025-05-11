import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_data.dart';
import 'token_manager.dart';
import '../config/environment_config.dart';

class RouteService {
  String get baseUrl => EnvironmentConfig.baseUrl;

  /// Fetches route data from the API with pagination support
  /// 
  /// [page] - The page number to fetch (starts at 1)
  /// 
  /// The API returns 4 routes per page. To get the next page, increment the page parameter.
  /// Returns an empty list when there are no more routes or if an error occurs.
  Future<List<RouteData>> getRoutes({int page = 1}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        ...TokenManager.getAuthHeader(),
      };

      print('----------------------------------');
      print('Buscando rotas - Página: $page');
      print('----------------------------------');

      // Add the page query parameter to implement pagination
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/route?page=$page'),
        headers: headers,
      );
      
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Mostrar informações sobre cada rota
        if (data.containsKey('data') && data['data'] is List) {
          final routes = data['data'] as List;
          print('Número de rotas retornadas: ${routes.length}');
          
          for (var i = 0; i < routes.length; i++) {
            var route = routes[i];
            print('----------------------------------');
            print('Rota ${i+1}:');
            print('ID: ${route['id']}');
            print('Status: ${route['route_status_id']}');
            print('Veículo ID: ${route['vehicle_id']}');
            print('Velocidade Media: ${route['velocity_average']}');
            print('Pontos: ${route['points']}');
            print('Pegada de Carbono: ${route['carbon_footprint']}');
            print('Distância: ${route['distance_km']}');
            
            if (route['vehicle'] != null) {
              var vehicle = route['vehicle'];
              print('Veículo:');
              print('  Nome: ${vehicle['name']}');
              print('  CO2 por Km: ${vehicle['co2_per_km']}');
              print('  Pontos por Km: ${vehicle['points_per_km']} (tipo: ${vehicle['points_per_km'].runtimeType})');
            }
            
            if (route['route_points'] != null && route['route_points'] is List) {
              print('Pontos da rota: ${(route['route_points'] as List).length}');
            }
          }
        }
        
        // Convert the data to a list of RouteData objects
        List<RouteData> routeList = (data['data'] as List)
            .map((routeJson) => RouteData.fromJson(routeJson))
            .toList();
            
        return routeList;
      } else {
        print('----------------------------------');
        print('Erro ao obter rotas: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        print('----------------------------------');
        throw Exception('Failed to fetch routes: ${response.statusCode}');
      }
    } catch (e) {
      print('----------------------------------');
      print('Erro ao buscar rotas: $e');
      print('----------------------------------');
      return [];
    }
  }
} 