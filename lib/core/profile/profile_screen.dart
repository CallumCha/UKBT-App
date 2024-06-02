import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: const Center(child: Text('No user found.')),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/tournaments');
            }
          },
        ),
      );
    }

    return FutureBuilder<bool>(
      future: authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final isAdmin = snapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${user.displayName ?? 'No name'}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text('Email: ${user.email ?? 'No email'}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text('Role: ${isAdmin ? 'Admin' : 'User'}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await authService.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Sign Out'),
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
      },
    );
  }
}
