// Re-exportar todos los servicios API para mantener compatibilidad
import 'base_api_service.dart';
import 'auth_api_service.dart';
import 'game_api_service.dart';
import 'participation_api_service.dart';
import 'notification_api_service.dart';

class ApiService {
  // Delegación a BaseApiService para gestión de tokens
  static Future<void> setToken(String token) => BaseApiService.setToken(token);
  static Future<String?> getToken() => BaseApiService.getToken();
  static Future<void> clearToken() => BaseApiService.clearToken();

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String emailOrUsername, String password) =>
      AuthApiService.login(emailOrUsername, password);

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) => AuthApiService.register(
    username: username,
    email: email,
    password: password,
    firstName: firstName,
    lastName: lastName,
  );

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) =>
      AuthApiService.updateProfile(userData);

  static Future<Map<String, dynamic>> getCurrentUser() => AuthApiService.getCurrentUser();
  static Future<Map<String, dynamic>> getUserRanking() => AuthApiService.getUserRanking();

  // Game endpoints
  static Future<Map<String, dynamic>> getGames({bool activeOnly = true}) =>
      GameApiService.getGames(activeOnly: activeOnly);

  static Future<Map<String, dynamic>> getGame(String gameId) => GameApiService.getGame(gameId);
  static Future<Map<String, dynamic>> getMatch(String gameId, String matchId) => GameApiService.getMatch(gameId, matchId);
  static Future<Map<String, dynamic>> getBanners() => GameApiService.getBanners();
  static Future<Map<String, dynamic>> healthCheck() => GameApiService.healthCheck();

  // Participation endpoints
  static Future<Map<String, dynamic>> joinGame(String gameId) =>
      ParticipationApiService.joinGame(gameId);

  static Future<Map<String, dynamic>> getUserParticipations() =>
      ParticipationApiService.getUserParticipations();

  static Future<Map<String, dynamic>> makePrediction({
    required String gameId,
    required int week,
    required String matchId,
    required String selectedTeam,
  }) => ParticipationApiService.makePrediction(
    gameId: gameId,
    week: week,
    matchId: matchId,
    selectedTeam: selectedTeam,
  );

  static Future<Map<String, dynamic>> getGameLeaders(String gameId) =>
      ParticipationApiService.getGameLeaders(gameId);

  static Future<Map<String, dynamic>> getMatchPredictionStats(String gameId, String matchId) =>
      ParticipationApiService.getMatchPredictionStats(gameId, matchId);

  static Future<Map<String, dynamic>> getGameParticipations(String gameId) =>
      ParticipationApiService.getGameParticipations(gameId);

  // Notification endpoints
  static Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) => NotificationApiService.getNotifications(
    limit: limit,
    offset: offset,
    unreadOnly: unreadOnly,
  );

  static Future<Map<String, dynamic>> getUnreadNotificationsCount() =>
      NotificationApiService.getUnreadNotificationsCount();

  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) =>
      NotificationApiService.markNotificationAsRead(notificationId);

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() =>
      NotificationApiService.markAllNotificationsAsRead();
}
