import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'package:ukbtapp/core/auth/models/user_model.dart';
import 'package:ukbtapp/core/widgets/tournament_history_widget.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Map<String, dynamic>> _tournaments = [];
  bool _showAllTournaments = false;
  bool _isGuestUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.isAnonymous) {
        setState(() {
          _isGuestUser = true;
        });
      } else {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = User.fromDocument(doc);
          final tournamentHistory = userData.tournamentHistory;
          tournamentHistory.sort((a, b) => b['date'].compareTo(a['date']));
          setState(() {
            _user = userData;
            _tournaments = tournamentHistory;
          });
        }
      }
    }
  }

  void _signOut() async {
    await auth.FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Color _getPositionColor(int position) {
    if (position == 1) return Colors.yellow[700]!;
    if (position == 2) return Colors.grey[300]!;
    if (position == 3) return Colors.brown[600]!;
    return Colors.transparent; // Changed to transparent for non-top 3 positions
  }

  Color _getTextColor(int position) {
    return position <= 3 ? Colors.black : Colors.white;
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      return '${dateTime.day.toString().padLeft(2, '0')} ${dateTime.month.toString().padLeft(2, '0')} ${dateTime.year}';
    } else if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')} ${date.month.toString().padLeft(2, '0')} ${date.year}';
    } else {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGuestUser) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Guest Profile'),
          centerTitle: true,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _signOut,
            child: const Text('Sign Out'),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Sign Out', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_user!.email),
                    Text('Admin (user type)', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 100,
              color: Colors.grey[300],
              child: const Center(child: Text('Placeholder box')),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Tournaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_tournaments.length > 4)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllTournaments = !_showAllTournaments;
                              });
                            },
                            child: Text(_showAllTournaments ? 'Show Less' : 'View More'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _showAllTournaments ? _tournaments.length : min(4, _tournaments.length),
                      itemBuilder: (context, index) {
                        final tournament = _tournaments[index];
                        final position = tournament['position'];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            color: _getPositionColor(position),
                            child: Center(
                              child: Text(
                                '$position',
                                style: TextStyle(
                                  color: _getTextColor(position),
                                  fontSize: 20, // Increased font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(tournament['tournamentName']),
                          subtitle: Text('Partner: ${tournament['partner']['name']}'),
                          trailing: Text(_formatDate(tournament['date'])),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
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
