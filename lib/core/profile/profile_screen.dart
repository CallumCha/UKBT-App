import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'package:ukbtapp/core/auth/models/user_model.dart';
import 'package:ukbtapp/core/widgets/tournament_history_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _user = User.fromDocument(doc);
      });
    }
  }

  void _signOut() async {
    await auth.FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(_user!.name),
            subtitle: Text(_user!.email),
          ),
          Expanded(
            child: TournamentHistoryWidget(user: _user!),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _signOut,
            child: const Text('Sign Out'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Assuming profile is at index 1
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/tournaments');
          }
        },
      ),
    );
  }
}
