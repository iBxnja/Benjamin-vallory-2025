import 'user.dart';
import 'game.dart';
import 'prediction.dart';

class Participation {
  final String id;
  final User user;
  final Game game;
  final List<Prediction> predictions;
  final int livesRemaining;
  final int totalPoints;
  final bool isEliminated;
  final int? eliminationWeek;
  final DateTime joinedAt;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Participation({
    required this.id,
    required this.user,
    required this.game,
    required this.predictions,
    required this.livesRemaining,
    required this.totalPoints,
    required this.isEliminated,
    this.eliminationWeek,
    required this.joinedAt,
    required this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
      id: json['_id'] ?? json['id'],
      user: User.fromJson(json['userId'] is Map ? json['userId'] : {}),
      game: Game.fromJson(json['gameId'] is Map ? json['gameId'] : {}),
      predictions: (json['predictions'] as List<dynamic>?)
          ?.map((prediction) => Prediction.fromJson(prediction))
          .toList() ?? [],
      livesRemaining: json['livesRemaining'] ?? 3,
      totalPoints: json['totalPoints'] ?? 0,
      isEliminated: json['isEliminated'] ?? false,
      eliminationWeek: json['eliminationWeek'],
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : DateTime.now(),
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt']) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'game': game.toJson(),
      'predictions': predictions.map((prediction) => prediction.toJson()).toList(),
      'livesRemaining': livesRemaining,
      'totalPoints': totalPoints,
      'isEliminated': isEliminated,
      'eliminationWeek': eliminationWeek,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  List<Prediction> get currentWeekPredictions {
    return predictions.where((p) => p.week == game.currentWeek).toList();
  }

  bool hasPredictionForMatch(String matchId, {int? week}) {
    if (week != null) {
      return predictions.any((p) => p.matchId == matchId && p.week == week);
    }
    return predictions.any((p) => p.matchId == matchId);
  }
}
