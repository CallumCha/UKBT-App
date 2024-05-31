import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> anonLogin() async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      print('Anonymous login failed: $e');
    }
  }

  Future<User?> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _createOrUpdateUser(user);
      }

      return user;
    } catch (e) {
      print('Google login failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> _createOrUpdateUser(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      final data = {
        'namef': user.displayName?.split(' ').first ?? '',
        'namel': user.displayName?.split(' ').last ?? '',
        'elo': 1200,
        'uid': user.uid,
        'ukbtno': await _generateUkbtno(),
      };

      await userDoc.set(data);
    }
  }

  Future<int> _generateUkbtno() async {
    // Generate a unique 4-digit UKBT number
    int ukbtno;
    bool exists = true;
    final rand = Random();

    do {
      ukbtno = (rand.nextInt(9000) + 1000);
      final snapshot = await _db.collection('users').where('ukbtno', isEqualTo: ukbtno).get();
      if (snapshot.docs.isEmpty) {
        exists = false;
      }
    } while (exists);

    return ukbtno;
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}
