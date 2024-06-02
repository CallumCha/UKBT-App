class KnockoutRound {
  final String round;
  final List<Map<String, dynamic>> matches;

  KnockoutRound({
    required this.round,
    required this.matches,
  });

  factory KnockoutRound.fromMap(Map<String, dynamic> data) {
    return KnockoutRound(
      round: data['round'] as String,
      matches: List<Map<String, dynamic>>.from(data['matches']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'round': round,
      'matches': matches,
    };
  }
}
