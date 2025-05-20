import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';
import 'api_client.dart';

class VehicleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _apiClient.get('mobile/vehicle/all');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> vehiclesData = responseData['data'];
        
        return vehiclesData.map((vehicleData) => Vehicle.fromJson(vehicleData)).toList();
      } else {
        throw Exception('Falha ao buscar veículos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar veículos: $e');
    }
  }

  Future<bool> updateUserVehicle(int vehicleId) async {
    try {
      final response = await _apiClient.patch(
        'mobile/user/user-vehicle',
        body: {
          'vehicle_id': vehicleId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar veículo: $e');
    }
  }
} 