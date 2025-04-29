/// Classe para gerenciar as URLs da API
class EnvironmentConfig {
  /// Instância singleton
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  
  factory EnvironmentConfig() {
    return _instance;
  }
  
  EnvironmentConfig._internal();
  
  /// Define se está usando a URL de produção ou local
  static bool _isProduction = false;
  
  static const String productionUrl = 'http://155.138.160.56/api/v1';
  
  static const String localUrl = 'http://192.168.1.151:8000/api/v1';
  // Para iOS ou teste no navegador, use:
  // static const String localUrl = 'http://localhost:8000/api/v1';
  
  /// Obtém a URL base ativa
  static String get baseUrl {
    return _isProduction ? productionUrl : localUrl;
  }
  
  /// Verifica se está usando ambiente de produção
  static bool get isProduction => _isProduction;
  
  /// Muda para URL de produção
  static void useProduction() {
    _isProduction = true;
    print('API: Usando servidor de produção - $productionUrl');
  }
  
  /// Muda para URL local
  static void useLocal() {
    _isProduction = false;
    print('API: Usando servidor local - $localUrl');
  }
  
  /// Alterna entre produção e local
  static void toggle() {
    _isProduction = !_isProduction;
    print('API: Usando ${_isProduction ? "servidor de produção" : "servidor local"} - ${baseUrl}');
  }
} 