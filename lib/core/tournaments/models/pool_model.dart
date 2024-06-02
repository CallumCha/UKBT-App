class Pool {
  String id;
  String name;
  int noMatches;
  List<Map<String, dynamic>> teams;
  List<Map<String, dynamic>> matches;
  List<Map<String, dynamic>> standings;

  Pool({
    required this.id,
    required this.name,
    required this.noMatches,
    required this.teams,
    required this.matches,
    required this.standings,
  });

  factory Pool.fromMap(Map<String, dynamic> map) {
    return Pool(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      noMatches: map['noMatches'] as int,
      teams: (map['teams'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      matches: (map['matches'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      standings: (map['standings'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'noMatches': noMatches,
      'teams': teams,
      'matches': matches,
      'standings': standings,
    };
  }
}
