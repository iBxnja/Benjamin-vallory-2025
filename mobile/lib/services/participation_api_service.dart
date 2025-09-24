import 'base_api_service.dart';

class ParticipationApiService {
  // Participation endpoints
  static Future<Map<String, dynamic>> joinGame(String gameId) async {
    return BaseApiService.postWithAuth('/participations/join/$gameId');
  }

  static Future<Map<String, dynamic>> getUserParticipations() async {
    return BaseApiService.getWithAuth('/participations/user');
  }

  static Future<Map<String, dynamic>> makePrediction({
    required String gameId,
    required int week,
    required String matchId,
    required String selectedTeam,
  }) async {
    return BaseApiService.postWithAuth('/participations/predict', {
      'gameId': gameId,
      'week': week,
      'matchId': matchId,
      'selectedTeam': selectedTeam,
    });
  }

  static Future<Map<String, dynamic>> getGameLeaders(String gameId) async {
    return BaseApiService.getWithAuth('/participations/leaders/$gameId');
  }

  static Future<Map<String, dynamic>> getMatchPredictionStats(String gameId, String matchId) async {
    return BaseApiService.getWithAuth('/participations/stats/$gameId/$matchId');
  }

  static Future<Map<String, dynamic>> getGameParticipations(String gameId) async {
    return BaseApiService.getWithAuth('/participations/game/$gameId');
  }
}
