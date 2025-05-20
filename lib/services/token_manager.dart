import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'auth_token_type';
  static const String _tokenExpiryKey = 'auth_token_expiry';

  static String? _token;
  static String? _tokenType;
  static int? _expiresIn;

  static String? getToken() {
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static String? getTokenType() {
    return _tokenType;
  }

  static Future<void> setTokenType(String tokenType) async {
    _tokenType = tokenType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenTypeKey, tokenType);
  }

  static int? getExpiresIn() {
    return _expiresIn;
  }

  static Future<void> setExpiresIn(int expiresIn) async {
    _expiresIn = expiresIn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenExpiryKey, expiresIn);
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenType = prefs.getString(_tokenTypeKey);
    _expiresIn = prefs.getInt(_tokenExpiryKey);
  }

  static Future<void> clearToken() async {
    _token = null;
    _tokenType = null;
    _expiresIn = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_tokenExpiryKey);
  }

  static bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }

  static Map<String, String> getAuthHeader() {
    if (!hasToken()) return {};
    
    return {
      'Authorization': '${_tokenType ?? 'Bearer'} $_token',
    };
  }
} 