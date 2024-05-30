import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get the current user
  User? get user => _auth.currentUser;

  // Anonymous login method
  Future<void> anonLogin() async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      print('Anonymous login failed: $e');
      // Handle error appropriately
    }
  }

  // Google login method
  Future<User?> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null; // User aborted the sign-in

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
    } on FirebaseAuthException catch (e) {
      print('Google login failed: $e');
      // Handle error appropriately
      return null;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Create or update user in Firestore
  Future<void> _createOrUpdateUser(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      final data = {
        'namef': user.displayName?.split(' ').first ?? '',
        'namel': user.displayName?.split(' ').last ?? '',
        'rank': 0,
        'uid': user.uid,
        'ukbtno': await _generateUniqueUkbtno(),
      };

      await userDoc.set(data);
    }
  }

// Generate a unique 4-digit UKBT number
  Future<int> _generateUniqueUkbtno() async {
    final random = Random();
    int ukbtno;

    while (true) {
      ukbtno = random.nextInt(9000) + 1000; // Generates a number between 1000 and 9999

      final querySnapshot = await _db.collection('users').where('ukbtno', isEqualTo: ukbtno).get();

      if (querySnapshot.docs.isEmpty) {
        break;
      }
    }

    return ukbtno;
  }
}
