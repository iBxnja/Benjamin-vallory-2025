class Prediction {
  final int week;
  final String matchId;
  final String selectedTeam; // 'home', 'visitor', or 'draw'
  final bool? isCorrect;
  final int? pointsEarned;
  final DateTime createdAt;

  Prediction({
    required this.week,
    required this.matchId,
    required this.selectedTeam,
    this.isCorrect,
    this.pointsEarned,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      week: json['week'] ?? 1,
      matchId: json['matchId'] ?? '',
      selectedTeam: json['selectedTeam'] ?? '',
      isCorrect: json['isCorrect'],
      pointsEarned: json['pointsEarned'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week,
      'matchId': matchId,
      'selectedTeam': selectedTeam,
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
