import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'package:ukbtapp/core/auth/models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _addNewPlayer() async {
    final random = Random();
    final userModel = UserModel(
      id: '', // Firestore will generate the ID
      name: 'User${random.nextInt(10000)}',
      email: 'user${random.nextInt(10000)}@example.com',
      elo: random.nextInt(3000),
      admin: false,
      ukbtno: (random.nextInt(9000) + 1000).toString(),
    );

    await FirebaseFirestore.instance.collection('users').add(userModel.toMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Home Screen'),
            ElevatedButton(
              onPressed: _addNewPlayer,
              child: const Text('Add New Player'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/tournaments');
          }
        },
      ),
    );
  }
}
