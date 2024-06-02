class Team {
  final String ukbtno1;
  final String ukbtno2;
  final String user1Name;
  final String user2Name;
  final String elo1;
  final String elo2;

  Team({
    required this.ukbtno1,
    required this.ukbtno2,
    required this.user1Name,
    required this.user2Name,
    required this.elo1,
    required this.elo2,
  });

  Map<String, String> toMap() {
    return {
      'ukbtno1': ukbtno1,
      'ukbtno2': ukbtno2,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'elo1': elo1,
      'elo2': elo2,
    };
  }
}
