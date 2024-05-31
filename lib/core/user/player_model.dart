class Player {
  final String uid;
  final String email;
  final String name;
  final int elo;
  final String ukbtno;
  final List<Map<String, dynamic>> tournamentHistory;
  final List<Map<String, dynamic>> eloHistory;

  Player({
    required this.uid,
    required this.email,
    required this.name,
    required this.elo,
    required this.ukbtno,
    required this.tournamentHistory,
    required this.eloHistory,
  });

  factory Player.fromMap(Map<String, dynamic> data) {
    return Player(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      elo: data['elo'],
      ukbtno: data['ukbtno'],
      tournamentHistory: List<Map<String, dynamic>>.from(data['tournamentHistory']),
      eloHistory: List<Map<String, dynamic>>.from(data['eloHistory']),
    );
  }
}
