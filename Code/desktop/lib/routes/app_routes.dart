import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../authentication/forgot_password_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String initial = '/';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found!'),
            ),
          ),
        );
    }
  }
}
