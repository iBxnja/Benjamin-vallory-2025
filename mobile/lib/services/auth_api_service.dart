import 'base_api_service.dart';

class AuthApiService {
  // Auth endpoints
  static Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    return BaseApiService.postPublic('/users/login', {
      'emailOrUsername': emailOrUsername,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return BaseApiService.postPublic('/users/register', {
      'username': username,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    return BaseApiService.putWithAuth('/users/profile', userData);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    return BaseApiService.getWithAuth('/users/me');
  }

  static Future<Map<String, dynamic>> getUserRanking() async {
    return BaseApiService.getWithAuth('/users/ranking/global');
  }
}
