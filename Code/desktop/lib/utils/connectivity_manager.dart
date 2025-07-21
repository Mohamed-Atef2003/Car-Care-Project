import 'package:flutter/material.dart';

class ConnectivityManager with ChangeNotifier {
  bool _isConnected = true;
  
  bool get isConnected => _isConnected;

  ConnectivityManager() {
    // In a real app, we would initialize connectivity monitoring here
    // For now, we'll assume the device is always connected
  }

  // Mock method to simulate checking connectivity
  Future<void> checkConnectivity() async {
    // For development/testing purposes, we'll just assume we're connected
    _isConnected = true;
    notifyListeners();
  }

  // Method to manually set connectivity status (for testing)
  void setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();
    }
  }
}