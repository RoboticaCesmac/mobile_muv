// import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia o token de autenticação globalmente na aplicação
class TokenManager {
  // Chaves para armazenar dados
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'auth_token_type';
  static const String _tokenExpiryKey = 'auth_token_expiry';

  // Cache em memória para acesso rápido
  static String? _token;
  static String? _tokenType;
  static int? _expiresIn;

  /// Retorna o token atual
  static String? getToken() {
    return _token;
  }

  /// Define o token atual
  static Future<void> setToken(String token) async {
    _token = token;
    // Removido temporariamente o armazenamento persistente
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString(_tokenKey, token);
  }

  /// Retorna o tipo do token (geralmente "Bearer")
  static String? getTokenType() {
    return _tokenType;
  }

  /// Define o tipo do token
  static Future<void> setTokenType(String tokenType) async {
    _tokenType = tokenType;
    // Removido temporariamente o armazenamento persistente
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString(_tokenTypeKey, tokenType);
  }

  /// Retorna o tempo de expiração do token
  static int? getExpiresIn() {
    return _expiresIn;
  }

  /// Define o tempo de expiração do token
  static Future<void> setExpiresIn(int expiresIn) async {
    _expiresIn = expiresIn;
    // Removido temporariamente o armazenamento persistente
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt(_tokenExpiryKey, expiresIn);
  }

  /// Carrega os dados do token do armazenamento persistente
  static Future<void> loadToken() async {
    // Removido temporariamente o carregamento persistente
    // final prefs = await SharedPreferences.getInstance();
    // _token = prefs.getString(_tokenKey);
    // _tokenType = prefs.getString(_tokenTypeKey);
    // _expiresIn = prefs.getInt(_tokenExpiryKey);
  }

  /// Limpa o token (para logout)
  static Future<void> clearToken() async {
    _token = null;
    _tokenType = null;
    _expiresIn = null;
    
    // Removido temporariamente a limpeza persistente
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove(_tokenKey);
    // await prefs.remove(_tokenTypeKey);
    // await prefs.remove(_tokenExpiryKey);
  }

  /// Verifica se o token existe
  static bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }

  /// Retorna o cabeçalho de autorização formatado para requisições HTTP
  static Map<String, String> getAuthHeader() {
    if (!hasToken()) return {};
    
    return {
      'Authorization': '${_tokenType ?? 'Bearer'} $_token',
    };
  }
} 