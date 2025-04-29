import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../services/token_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    Timer(
      const Duration(seconds: 2),
      () {
        // Verifica se existe um token salvo
        if (TokenManager.hasToken()) {
          // Se existir, vai para a HomePage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        } else {
          // Se não existir, vai para a LoginPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004341), // #004341 em hex
      body: Center(
        child: Image.asset(
          'assets/LogoMarcaBranca.png',
          width: 200,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.error_outline,
              size: 120,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }
} 