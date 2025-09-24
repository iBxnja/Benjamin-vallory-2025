import 'base_api_service.dart';

class GameApiService {
  // Game endpoints
  static Future<Map<String, dynamic>> getGames({bool activeOnly = true}) async {
    final route = activeOnly ? '/games?active=true' : '/games';
    return BaseApiService.getWithAuth(route); // Cambiar a getWithAuth
  }

  static Future<Map<String, dynamic>> getGame(String gameId) async {
    return BaseApiService.getWithAuth('/games/$gameId');
  }

  static Future<Map<String, dynamic>> getMatch(String gameId, String matchId) async {
    return BaseApiService.getWithAuth('/games/$gameId/match/$matchId');
  }

  // Banner endpoints
  static Future<Map<String, dynamic>> getBanners() async {
    return BaseApiService.getPublic('/banners'); // Los banners son públicos
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    return BaseApiService.getPublic('/health');
  }
}
