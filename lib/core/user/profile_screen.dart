import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:ukbtapp/core/user/player_model.dart';
import 'package:ukbtapp/core/user/player_service.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final playerService = Provider.of<PlayerService>(context);

    return StreamBuilder<auth.User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text('Not logged in')),
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
        final user = snapshot.data!;
        return FutureBuilder<Player?>(
          future: playerService.getPlayer(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData) {
              return Scaffold(
                body: Center(child: Text('Player not found')),
              );
            }
            final player = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: Text('Profile'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${player.name}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('Email: ${player.email}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('Elo: ${player.elo}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('UKBT Number: ${player.ukbtno}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await authService.signOut();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              ),
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
          },
        );
      },
    );
  }
}
