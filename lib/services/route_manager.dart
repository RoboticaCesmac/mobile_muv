import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class RouteManager {
  static const String _offlineRoutesKey = 'offline_routes';
  static const String _currentRouteKey = 'current_route';

  static Future<void> addPointToCurrentRoute(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoute = prefs.getStringList(_currentRouteKey) ?? [];
    
    final point = RoutePoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );

    currentRoute.add(jsonEncode(point.toJson()));
    await prefs.setStringList(_currentRouteKey, currentRoute);
  }

  static Future<void> finishCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoute = prefs.getStringList(_currentRouteKey) ?? [];
    
    if (currentRoute.isNotEmpty) {
      final offlineRoutes = prefs.getStringList(_offlineRoutesKey) ?? [];
      offlineRoutes.add(jsonEncode(currentRoute));
      await prefs.setStringList(_offlineRoutesKey, offlineRoutes);
      await prefs.remove(_currentRouteKey);
    }
  }

  static Future<List<RoutePoint>> getCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoute = prefs.getStringList(_currentRouteKey) ?? [];
    
    return currentRoute.map((pointJson) {
      final Map<String, dynamic> pointMap = jsonDecode(pointJson);
      return RoutePoint.fromJson(pointMap);
    }).toList();
  }

  static Future<List<List<RoutePoint>>> getOfflineRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final offlineRoutes = prefs.getStringList(_offlineRoutesKey) ?? [];
    
    return offlineRoutes.map((routeJson) {
      final List<dynamic> routeList = jsonDecode(routeJson);
      return routeList.map((pointJson) {
        final Map<String, dynamic> pointMap = jsonDecode(pointJson);
        return RoutePoint.fromJson(pointMap);
      }).toList();
    }).toList();
  }

  static Future<void> removeOfflineRoute(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineRoutes = prefs.getStringList(_offlineRoutesKey) ?? [];
    
    if (index >= 0 && index < offlineRoutes.length) {
      offlineRoutes.removeAt(index);
      await prefs.setStringList(_offlineRoutesKey, offlineRoutes);
    }
  }

  static Future<void> clearAllOfflineRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineRoutesKey);
  }

  static Future<void> clearCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentRouteKey);
  }

  static Future<void> clearAllRouteData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentRouteKey);
    await prefs.remove(_offlineRoutesKey);
  }

  static Future<int> getTotalOfflinePointsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoute = prefs.getStringList(_currentRouteKey) ?? [];
    final offlineRoutes = prefs.getStringList(_offlineRoutesKey) ?? [];
    
    int totalPoints = currentRoute.length;
    
    for (var routeJson in offlineRoutes) {
      try {
        final List<dynamic> routeList = jsonDecode(routeJson);
        totalPoints += routeList.length;
      } catch (e) {
      }
    }
    
    return totalPoints;
  }

  static Future<void> debugPrintRouteInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRoute = prefs.getStringList(_currentRouteKey) ?? [];
      final offlineRoutes = prefs.getStringList(_offlineRoutesKey) ?? [];
      
      int i = 0;
      for (var routeJson in offlineRoutes) {
        try {
          final List<dynamic> routeList = jsonDecode(routeJson);
          i++;
        } catch (e) {
          i++;
        }
      }
    } catch (e) {
    }
  }
} 