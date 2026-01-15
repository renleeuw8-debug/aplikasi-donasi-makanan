import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user has valid token from API
    final token = ApiService.token;

    if (token == null || token.isEmpty) {
      // No token = not logged in, show login
      return const LoginScreen();
    }

    // Token exists, show login to get role and determine home page
    return const LoginScreen();
  }
}
