import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String ukbtno;
  final bool isAdmin;
  final List<Map<String, dynamic>> tournamentHistory;
  int elo;
  List<Map<String, dynamic>> rankChanges;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.ukbtno,
    required this.isAdmin,
    required this.tournamentHistory,
    this.elo = 1500,
    this.rankChanges = const [],
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      ukbtno: data['ukbtno'] ?? '',
      isAdmin: data['admin'] ?? false,
      tournamentHistory: List<Map<String, dynamic>>.from(data['tournamentHistory'] ?? []),
      elo: data['elo'] ?? 1500,
      rankChanges: List<Map<String, dynamic>>.from(data['rankChanges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'ukbtno': ukbtno,
      'isAdmin': isAdmin,
      'tournamentHistory': tournamentHistory,
      'elo': elo,
      'rankChanges': rankChanges,
    };
  }
}
