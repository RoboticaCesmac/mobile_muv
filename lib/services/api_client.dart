import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../config/environment_config.dart';

class ApiClient {
  String get baseUrl => EnvironmentConfig.baseUrl;

  Future<http.Response> get(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
      ...TokenManager.getAuthHeader(),
    };

    return http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = {
      'Content-Type': 'application/json',
      ...TokenManager.getAuthHeader(),
    };

    return http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = {
      'Content-Type': 'application/json',
      ...TokenManager.getAuthHeader(),
    };

    return http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = {
      'Content-Type': 'application/json',
      ...TokenManager.getAuthHeader(),
    };

    return http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
      ...TokenManager.getAuthHeader(),
    };

    return http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
  }
} 