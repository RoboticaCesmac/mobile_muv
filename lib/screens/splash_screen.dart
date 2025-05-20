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
        if (TokenManager.hasToken()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        } else {
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
      backgroundColor: const Color(0xFF004341),
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