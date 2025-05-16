import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Classe para gerenciar as URLs da API
class EnvironmentConfig {
  /// Instância singleton
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  
  factory EnvironmentConfig() {
    return _instance;
  }
  
  EnvironmentConfig._internal();
  
  /// Define se está usando a URL de produção ou local
  static bool _isProduction = true;
  
  /// Obtém a URL base ativa
  static String get baseUrl {
    return _isProduction 
        ? dotenv.env['PRODUCTION_URL'] ?? ''
        : dotenv.env['LOCAL_URL'] ?? 'http://localhost:8000/api/v1';
  }

  /// Obtém a chave da API do Google Maps
  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }
  
  /// Verifica se está usando ambiente de produção
  static bool get isProduction => _isProduction;
  
  /// Muda para URL de produção
  static void useProduction() {
    _isProduction = true;
    print('API: Usando servidor de produção - $baseUrl');
  }
  
  /// Muda para URL local
  static void useLocal() {
    _isProduction = false;
    print('API: Usando servidor local - $baseUrl');
  }
  
  /// Alterna entre produção e local
  static void toggle() {
    _isProduction = !_isProduction;
    print('API: Usando ${_isProduction ? "servidor de produção" : "servidor local"} - $baseUrl');
  }
} 