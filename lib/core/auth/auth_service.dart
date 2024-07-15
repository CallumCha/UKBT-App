
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
    } on FirebaseAuthException {
      print('Anonymous login failed: \$e');
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
      print('Google login failed: \$e');
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
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'elo': 1200,
        'uid': user.uid,
        'ukbtno': 'ukbtno\${await _generateUkbtno()}',
        'admin': false, // Default admin role set to false
      };

      await userDoc.set(data);
    }
  }

  Future<String> _generateUkbtno() async {
    // Generate a unique 5-digit UKBT number
    String ukbtno;
    bool exists = true;
    final rand = Random();

    do {
      int number = rand.nextInt(90000) + 10000; // Generate a unique 5-digit number
      ukbtno = number.toString();
      final snapshot = await _db.collection('users').where('ukbtno', isEqualTo: 'ukbtno\$ukbtno').get();
      if (snapshot.docs.isEmpty) {
        exists = false;
      }
    } while (exists);

    return ukbtno;
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      return userDoc.data()?['admin'] ?? false;
    }
    return false;
  }

  Future<void> registerUser(String name, String email, String password) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User user = result.user!;
    String ukbtno = await _generateUkbtno(); // Generate a unique 5-digit UKBT number

    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'elo': 1200,
      'admin': false,
      'ukbtno': 'ukbtno\$ukbtno',
    });
  }
}
