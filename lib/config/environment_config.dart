import 'package:flutter_dotenv/flutter_dotenv.dart';
class EnvironmentConfig {
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  
  factory EnvironmentConfig() {
    return _instance;
  }
  
  EnvironmentConfig._internal();
  
  static bool _isProduction = false;
  
  static String get baseUrl {
    return _isProduction 
        ? dotenv.env['PRODUCTION_URL'] ?? ''
        : dotenv.env['LOCAL_URL'] ?? 'http://localhost:8000/api/v1';
  }

  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }
  
  static bool get isProduction => _isProduction;
  
  static void useProduction() {
    _isProduction = true;
  }
  
  static void useLocal() {
    _isProduction = false;
  }
  
  static void toggle() {
    _isProduction = !_isProduction;
  }
} 