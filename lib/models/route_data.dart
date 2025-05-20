import 'package:intl/intl.dart';

class RouteData {
  final int id;
  final int routeStatusId;
  final int vehicleId;
  final num points;
  final num carbonFootprint;
  final num distanceKm;
  final num velocityAverage;
  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, RoutePoint> routePoints;
  final Vehicle vehicle;

  RouteData({
    required this.id,
    required this.routeStatusId,
    required this.vehicleId,
    required this.points,
    required this.carbonFootprint,
    required this.distanceKm,
    required this.velocityAverage,
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.routePoints,
    required this.vehicle,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    // Parse route points
    Map<String, RoutePoint> parsedRoutePoints = {};
    if (json['route_points'] != null && json['route_points'] is Map) {
      (json['route_points'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          try {
            parsedRoutePoints[key.toString()] = RoutePoint.fromJson(value);
          } catch (e) {
            print('Error parsing route point: $e');
          }
        }
      });
    }
    
    // Função auxiliar para converter qualquer valor para num de forma segura
    num toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }
    
    // Função auxiliar para converter data de forma segura
    DateTime toDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    // Safely parse vehicle
    Vehicle vehicleData;
    try {
      vehicleData = json['vehicle'] != null 
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>) 
          : Vehicle(
              id: 0,
              name: 'Unknown',
              co2PerKm: 0,
              iconPath: '',
              pointsPerKm: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
    } catch (e) {
      print('Error parsing vehicle: $e');
      vehicleData = Vehicle(
        id: 0,
        name: 'Error',
        co2PerKm: 0,
        iconPath: '',
        pointsPerKm: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    return RouteData(
      id: json['id'],
      routeStatusId: json['route_status_id'],
      vehicleId: json['vehicle_id'],
      points: toNum(json['points']),
      carbonFootprint: toNum(json['carbon_footprint']),
      distanceKm: toNum(json['distance_km']),
      velocityAverage: toNum(json['velocity_average']),
      startedAt: toDateTime(json['started_at']),
      endedAt: toDateTime(json['ended_at']),
      createdAt: toDateTime(json['created_at']),
      updatedAt: toDateTime(json['updated_at']),
      routePoints: parsedRoutePoints,
      vehicle: vehicleData,
    );
  }
}

class RoutePoint {
  final int id;
  final int routeId;
  final num latitude;
  final num longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutePoint({
    required this.id,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    // Função auxiliar para converter qualquer valor para num de forma segura
    num toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }
    
    // Função auxiliar para converter data de forma segura
    DateTime toDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return RoutePoint(
      id: json['id'],
      routeId: json['route_id'],
      latitude: toNum(json['latitude']),
      longitude: toNum(json['longitude']),
      createdAt: toDateTime(json['created_at']),
      updatedAt: toDateTime(json['updated_at']),
    );
  }
}

class Vehicle {
  final int id;
  final String name;
  final num co2PerKm;
  final String iconPath;
  final num pointsPerKm;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? iconUrl;

  Vehicle({
    required this.id,
    required this.name,
    required this.co2PerKm,
    required this.iconPath,
    required this.pointsPerKm,
    required this.createdAt,
    required this.updatedAt,
    this.iconUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Função auxiliar para converter qualquer valor para num de forma segura
    num toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }
    
    // Função auxiliar para converter data de forma segura
    DateTime toDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    String? iconUrl = json['icon_url'] as String?;
    
    return Vehicle(
      id: json['id'],
      name: json['name'],
      co2PerKm: toNum(json['co2_per_km']),
      iconPath: json['icon_path'],
      pointsPerKm: toNum(json['points_per_km']),
      createdAt: toDateTime(json['created_at']),
      updatedAt: toDateTime(json['updated_at']),
      iconUrl: iconUrl,
    );
  }
} 