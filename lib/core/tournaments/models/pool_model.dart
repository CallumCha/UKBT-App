class Pool {
  String name;
  List<Map<String, dynamic>> teams;
  List<Map<String, dynamic>> matches;
  List<Map<String, dynamic>> standings;

  Pool({
    required this.name,
    required this.teams,
    required this.matches,
    required this.standings,
  });

  factory Pool.fromMap(Map<String, dynamic> map) {
    return Pool(
      name: map['name'] as String? ?? 'Unknown',
      teams: (map['teams'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      matches: (map['matches'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      standings: (map['standings'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teams': teams,
      'matches': matches,
      'standings': standings,
    };
  }
}
