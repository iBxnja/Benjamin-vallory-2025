import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  List<Game> _games = [];
  Game? _selectedGame;
  bool _isLoading = false;
  String? _error;

  List<Game> get games => _games;
  Game? get selectedGame => _selectedGame;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadGames({bool activeOnly = true}) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.getGames(activeOnly: activeOnly);
      
      if (response['success']) {
        final gamesData = response['data']['games'] as List;
        _games = gamesData.map((game) => Game.fromJson(game)).toList();
      } else {
        _setError(response['message'] ?? 'Error al cargar juegos');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGame(String gameId) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.getGame(gameId);
      
      if (response['success']) {
        _selectedGame = Game.fromJson(response['data']['game']);
      } else {
        _setError(response['message'] ?? 'Error al cargar el juego');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void selectGame(Game game) {
    _selectedGame = game;
    notifyListeners();
  }

  void clearSelectedGame() {
    _selectedGame = null;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  List<Game> get activeGames => _games.where((game) => game.isActive).toList();
}
