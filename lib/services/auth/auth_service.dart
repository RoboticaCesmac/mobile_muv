import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../screens/home_page.dart';
import '../../screens/token_confirmation_page.dart';
import '../../screens/login_page.dart';
import '../../screens/new_password_page.dart';
import '../../screens/reset_password_token_page.dart';
import '../../screens/vehicle_selection_page.dart';
import '../../config/environment_config.dart';
import 'token_manager.dart';
import '../../services/validation_error_handler.dart';
import '../../models/api_error.dart';

class AuthService {
  String get baseUrl => EnvironmentConfig.baseUrl;

  Future<void> _saveToken(String token, String tokenType, int expiresIn) async {
    await TokenManager.setToken(token);
    await TokenManager.setTokenType(tokenType);
    await TokenManager.setExpiresIn(expiresIn);
  }

  Future<ApiError?> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login-mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        final String token = responseData['access_token'];
        final String tokenType = responseData['token_type'];
        final int expiresIn = responseData['expires_in'];
        final bool isFirstLogin = responseData['is_first_login'] ?? false;
        
        await _saveToken(token, tokenType, expiresIn);
        
        if (context.mounted) {
          if (isFirstLogin) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const VehicleSelectionPage()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        }
        return null;
      } else {
        final apiError = ValidationErrorHandler.handleResponse(response, context);
        if (apiError != null) {
          return apiError;
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao realizar login'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
      return null;
    }
  }

  Future<void> sendRegisterToken({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TokenConfirmationPage(
                email: email,
                password: password,
              ),
            ),
          );
        }
      } else {

        final apiError = ValidationErrorHandler.handleResponse(response, context);
        if (apiError == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Falha ao enviar token'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> sendPasswordResetToken({
    required String email,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-reset-password-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      ); 
      print(response.body);
      if (response.statusCode == 200) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordTokenPage(
                email: email,
              ),
            ),
          );
        }
      } else {

        final apiError = ValidationErrorHandler.handleResponse(response, context);
        if (apiError == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Falha ao enviar token de redefinição'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> confirmResetPasswordToken({
    required String email,
    required String token,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/confirm-reset-password-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewPasswordPage(
                email: email,
                token: token,
              ),
            ),
          );
        }
      } else {

        final apiError = ValidationErrorHandler.handleResponse(response, context);
        if (apiError == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Token inválido ou expirado'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String token,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': password,
          'token': token,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {

        final apiError = ValidationErrorHandler.handleResponse(response, context);
        if (apiError == null) {
          final responseData = jsonDecode(response.body);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Falha ao realizar cadastro'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> resetPassword({
    required String email,
    required String password,
    required String token,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': password,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha redefinida com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {

        final apiError = ValidationErrorHandler.handleResponse(response, context);
        if (apiError == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Falha ao redefinir a senha'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<bool> verifyToken() async {
    try {
      final token = TokenManager.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          ...TokenManager.getAuthHeader(),
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    await TokenManager.clearToken();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
} 
