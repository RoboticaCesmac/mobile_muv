import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/token_confirmation_page.dart';
import '../screens/login_page.dart';
import '../screens/new_password_page.dart';
import '../screens/reset_password_token_page.dart';
import '../screens/vehicle_selection_page.dart';
import '../config/environment_config.dart';
import 'token_manager.dart';

class AuthService {
  String get baseUrl => EnvironmentConfig.baseUrl;

  // Método para salvar o token no dispositivo
  Future<void> _saveToken(String token, String tokenType, int expiresIn) async {
    // Salva o token usando o TokenManager para acesso global
    await TokenManager.setToken(token);
    await TokenManager.setTokenType(tokenType);
    await TokenManager.setExpiresIn(expiresIn);
  }

  // Login
  Future<void> login({
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
      print('----------------------------------');
      print(Uri.parse('$baseUrl/auth/login-mobile'));
      print('----------------------------------');
      if (response.statusCode == 200) {
        // Decodifica a resposta JSON
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extrai os dados da resposta
        final String token = responseData['access_token'];
        final String tokenType = responseData['token_type'];
        final int expiresIn = responseData['expires_in'];
        final bool isFirstLogin = responseData['is_first_login'] ?? false;
        
        // Salva o token
        await _saveToken(token, tokenType, expiresIn);
        
        if (context.mounted) {
          if (isFirstLogin) {
            // Navega para a página de seleção de veículo para o primeiro login
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const VehicleSelectionPage()),
              (route) => false,
            );
          } else {
            // Navega para a HomePage para usuários que já completaram o onboarding
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao realizar login'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao enviar token'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Envio do token para redefinição de senha
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
          // Navega para a tela de confirmação de token para reset de senha
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordTokenPage(
                email: email,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao enviar token de redefinição'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
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
          // Navega para a tela de nova senha
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Registro com token
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

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navega para a tela de login e remove todas as rotas anteriores
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Falha ao realizar cadastro'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Redefinição de senha com token
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
            ),
          );
          // Navega para a tela de login e remove todas as rotas anteriores
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao redefinir a senha'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao se conectar com o servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 
