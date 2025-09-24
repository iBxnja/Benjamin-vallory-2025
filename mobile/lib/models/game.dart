import 'match.dart';

class Game {
  final String id;
  final String name;
  final List<Match> competition;
  final DateTime startDate;
  final DateTime? endDate;
  final int maxLives;
  final bool isActive;
  final int currentWeek;
  final int totalWeeks;
  final int participantCount;
  final int maxParticipants;
  final DateTime createdAt;
  final DateTime updatedAt;

  Game({
    required this.id,
    required this.name,
    required this.competition,
    required this.startDate,
    this.endDate,
    required this.maxLives,
    required this.isActive,
    required this.currentWeek,
    required this.totalWeeks,
    required this.participantCount,
    required this.maxParticipants,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      competition: (json['competition'] as List<dynamic>?)
          ?.map((match) => Match.fromJson(match))
          .toList() ?? [],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxLives: json['maxLives'] ?? 3,
      isActive: json['isActive'] ?? true,
      currentWeek: json['currentWeek'] ?? 1,
      totalWeeks: json['totalWeeks'] ?? 1,
      participantCount: json['participantCount'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 20,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'competition': competition.map((match) => match.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxLives': maxLives,
      'isActive': isActive,
      'currentWeek': currentWeek,
      'totalWeeks': totalWeeks,
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  List<Match> get currentWeekMatches {
    // Por simplicidad, asumimos 3 partidos por semana
    const matchesPerWeek = 3;
    final startIndex = (currentWeek - 1) * matchesPerWeek;
    final endIndex = startIndex + matchesPerWeek;
    
    if (startIndex >= competition.length) return [];
    
    return competition.sublist(
      startIndex, 
      endIndex > competition.length ? competition.length : endIndex
    );
  }

  bool get isFinished => currentWeek > totalWeeks;
}
