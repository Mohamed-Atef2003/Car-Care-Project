import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;
  static const String tokenKey = 'auth_token';

  AuthService(this._apiService, this._storageService);

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post('/login', {
        'email': email,
        'password': password,
      });

      if (response['token'] != null) {
        await _storageService.saveString(tokenKey, response['token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.remove(tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getString(tokenKey);
    return token != null;
  }
}
