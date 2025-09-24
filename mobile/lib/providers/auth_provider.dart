import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String emailOrUsername, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.login(emailOrUsername, password);
      
      if (response['success']) {
        final data = response['data'];
        _user = User.fromJson(data['user']);
        await ApiService.setToken(data['token']);
        return true;
      } else {
        _setError(response['message'] ?? 'Error al iniciar sesión');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (response['success']) {
        final data = response['data'];
        _user = User.fromJson(data['user']);
        await ApiService.setToken(data['token']);
        return true;
      } else {
        _setError(response['message'] ?? 'Error al registrarse');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    await ApiService.clearToken();
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final response = await ApiService.getCurrentUser();
        if (response['success']) {
          // print('🔍 loadUser - datos recibidos: ${response['data']}');
          _user = User.fromJson(response['data']);
          // print('🔍 loadUser - usuario cargado: ${_user?.username}, vidas: ${_user?.lives}');
          notifyListeners();
        }
      }
    } catch (e) {
      // print('🔍 loadUser - error: $e');
      // Si hay error al cargar el usuario, limpiar el token
      await ApiService.clearToken();
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await ApiService.getCurrentUser();
      if (response['success']) {
        // print('🔍 refreshUser - datos recibidos: ${response['data']}');
        _user = User.fromJson(response['data']);
        // print('🔍 refreshUser - usuario refrescado: ${_user?.username}, vidas: ${_user?.lives}');
        notifyListeners();
      }
    } catch (e) {
      // print('Error refreshing user: $e');
      // Don't logout on refresh error, just log it
    }
  }

  void clearError() {
    _setError(null);
  }
}
