
class Group {
  final String id;
  final String name;
  final String tournamentId;

  Group({
    required this.id,
    required this.name,
    required this.tournamentId,
  });

  factory Group.fromMap(Map<String, dynamic> map, String id) {
    return Group(
      id: id,
      name: map['name'] as String,
      tournamentId: map['tournamentId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tournamentId': tournamentId,
    };
  }
}
