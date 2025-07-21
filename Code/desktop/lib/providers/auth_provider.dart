import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuth = false;
  String? _token;

  bool get isAuth => _isAuth;
  String? get token => _token;
  
  Future<bool> tryAutoLogin() async {
    // Simple implementation to replace the deleted version
    return false;
  }
  
  Future<void> login(String email, String password) async {
    // Simple implementation
    _isAuth = true;
    _token = 'dummy-token';
    notifyListeners();
  }

  Future<void> register(String username, String email, String password) async {
    // Simple implementation
    _isAuth = true;
    _token = 'dummy-token';
    notifyListeners();
  }
  
  Future<void> logout() async {
    _isAuth = false;
      _token = null;
    notifyListeners();
  }
  
  Future<void> adminLogin() async {
    _isAuth = true;
    _token = 'admin-token';
    notifyListeners();
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    // Simple implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  // Add a dummy property for isFirebaseAvailable
  bool get isFirebaseAvailable => false;
} 