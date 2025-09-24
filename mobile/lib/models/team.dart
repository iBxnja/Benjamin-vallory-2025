class Team {
  final String name;
  final String flag;

  Team({
    required this.name,
    required this.flag,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] ?? '',
      flag: json['flag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'flag': flag,
    };
  }
}
