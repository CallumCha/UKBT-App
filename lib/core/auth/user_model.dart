class User {
  final String uid;
  final String email;
  final String name;
  final int elo;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.elo,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      elo: data['elo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'elo': elo,
    };
  }
}
