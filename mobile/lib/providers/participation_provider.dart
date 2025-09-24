import 'package:flutter/foundation.dart';
import '../models/participation.dart';
import '../services/api_service.dart';

class ParticipationProvider with ChangeNotifier {
  List<Participation> _participations = [];
  List<Participation> _gameLeaders = [];
  bool _isLoading = false;
  String? _error;

  List<Participation> get participations => _participations;
  List<Participation> get gameLeaders => _gameLeaders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  Future<void> loadUserParticipations() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.getUserParticipations();
      
      if (response['success']) {
        final participationsData = response['data']['participations'] as List;
        _participations = participationsData.map((part) => Participation.fromJson(part)).toList();
      } else {
        _setError(response['message'] ?? 'Error al cargar participaciones');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGameData(String gameId) async {
    try {
      // Recargar datos del juego para obtener estados actualizados de partidos
      await ApiService.getGame(gameId);
    } catch (e) {
      // print('Error loading game data: $e');
    }
  }

  Future<bool> joinGame(String gameId) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.joinGame(gameId);
      
      if (response['success']) {
        // Recargar participaciones después de unirse
        await loadUserParticipations();
        return true;
      } else {
        _setError(response['message'] ?? 'Error al unirse al juego');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> makePrediction({
    required String gameId,
    required int week,
    required String matchId,
    required String selectedTeam,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.makePrediction(
        gameId: gameId,
        week: week,
        matchId: matchId,
        selectedTeam: selectedTeam,
      );
      
      if (response['success']) {
        // Recargar participaciones después de hacer predicción
        await loadUserParticipations();
        return true;
      } else {
        _setError(response['message'] ?? 'Error al hacer predicción');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGameLeaders(String gameId) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.getGameLeaders(gameId);
      
      if (response['success']) {
        final leadersData = response['data']['leaders'] as List;
        _gameLeaders = leadersData.map((leader) => Participation.fromJson(leader)).toList();
      } else {
        _setError(response['message'] ?? 'Error al cargar líderes');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Participation? getParticipationForGame(String gameId) {
    try {
      return _participations.firstWhere((part) => part.game.id == gameId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _setError(null);
  }
}
