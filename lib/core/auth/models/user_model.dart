
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final int elo;
  final bool admin;
  final String ukbtno;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.elo,
    this.admin = false,
    required String ukbtno,
  }) : ukbtno = _validateUkbtno(ukbtno);

  static String _validateUkbtno(String ukbtno) {
    final regex = RegExp(r'^ukbtno\d{5}\$');
    if (!regex.hasMatch(ukbtno)) {
      throw ArgumentError('ukbtno must start with "ukbtno" followed by a five-digit number');
    }
    return ukbtno;
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      elo: data['elo'] ?? 0,
      admin: data['admin'] ?? false,
      ukbtno: data['ukbtno'] ?? 'ukbtno00000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'elo': elo,
      'admin': admin,
      'ukbtno': ukbtno,
    };
  }
}
