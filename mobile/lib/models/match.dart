import 'team.dart';

class Match {
  final String matchId;
  final Team home;
  final Team visitor;
  final DateTime date;
  final int? week; // Jornada a la que pertenece
  final MatchResult? result;
  final bool isFinished;
  final String? status;
  final DateTime? bettingDeadline;

  Match({
    required this.matchId,
    required this.home,
    required this.visitor,
    required this.date,
    this.week,
    this.result,
    required this.isFinished,
    this.status,
    this.bettingDeadline,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchId: json['matchId'] ?? '',
      home: Team.fromJson(json['home'] ?? {}),
      visitor: Team.fromJson(json['visitor'] ?? {}),
      date: DateTime.parse(json['date']),
      week: json['week'],
      result: json['result'] != null ? MatchResult.fromJson(json['result']) : null,
      isFinished: json['isFinished'] ?? false,
      status: json['status'],
      bettingDeadline: json['bettingDeadline'] != null ? DateTime.parse(json['bettingDeadline']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'home': home.toJson(),
      'visitor': visitor.toJson(),
      'date': date.toIso8601String(),
      'week': week,
      'result': result?.toJson(),
      'isFinished': isFinished,
      'status': status,
      'bettingDeadline': bettingDeadline?.toIso8601String(),
    };
  }

  String get displayName => '${home.name} vs ${visitor.name}';
}

class MatchResult {
  final int homeScore;
  final int visitorScore;
  final String winner; // 'home', 'visitor', 'draw'

  MatchResult({
    required this.homeScore,
    required this.visitorScore,
    required this.winner,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      homeScore: json['homeScore'] ?? 0,
      visitorScore: json['visitorScore'] ?? 0,
      winner: json['winner'] ?? 'draw',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeScore': homeScore,
      'visitorScore': visitorScore,
      'winner': winner,
    };
  }

  String get scoreDisplay => '$homeScore - $visitorScore';
}
