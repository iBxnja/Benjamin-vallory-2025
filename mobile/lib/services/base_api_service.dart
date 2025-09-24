import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class BaseApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<void> ensureToken() async {
    await getToken();
  }

  static Future<Map<String, dynamic>> handleResponse(http.Response response) async {
    final data = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Error en la petición');
    }
  }

  // Métodos genéricos con autenticación automática
  static Future<Map<String, dynamic>> getWithAuth(String route) async {
    await ensureToken();
    final response = await http.get(
      Uri.parse('$baseUrl$route'), // Sin duplicar /api
      headers: headers,
    );
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> postWithAuth(String route, [Map<String, dynamic>? formData]) async {
    await ensureToken();
    final response = await http.post(
      Uri.parse('$baseUrl$route'), // Sin duplicar /api
      headers: headers,
      body: formData != null ? json.encode(formData) : null,
    );
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> putWithAuth(String route, [Map<String, dynamic>? formData]) async {
    await ensureToken();
    final response = await http.put(
      Uri.parse('$baseUrl$route'), // Sin duplicar /api
      headers: headers,
      body: formData != null ? json.encode(formData) : null,
    );
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteWithAuth(String route) async {
    await ensureToken();
    final response = await http.delete(
      Uri.parse('$baseUrl$route'), // Sin duplicar /api
      headers: headers,
    );
    return handleResponse(response);
  }

  // Métodos sin autenticación para login/register
  static Future<Map<String, dynamic>> postPublic(String route, Map<String, dynamic> formData) async {
    final response = await http.post(
      Uri.parse('$baseUrl$route'), // Sin duplicar /api
      headers: {'Content-Type': 'application/json'},
      body: json.encode(formData),
    );
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPublic(String route) async {
    final response = await http.get(
      Uri.parse('$baseUrl$route'), // Sin duplicar /api
      headers: {'Content-Type': 'application/json'},
    );
    return handleResponse(response);
  }
}
