class User {
  final String uid;
  final String email;
  final String name;
  final int elo;
  final String ukbtno;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.elo,
    required this.ukbtno,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      elo: data['elo'],
      ukbtno: data['ukbtno'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'elo': elo,
      'ukbtno': ukbtno,
    };
  }
}
