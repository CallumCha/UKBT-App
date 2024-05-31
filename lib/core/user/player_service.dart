import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/user/player_model.dart';

class PlayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Player?> getPlayer(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return Player.fromMap(doc.data()!);
    }
    return null;
  }
}
