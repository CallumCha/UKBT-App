import 'package:flutter/material.dart';
import 'package:ukbtapp/home/home.dart';
import 'package:ukbtapp/login/login.dart';
import 'package:ukbtapp/services/auth.dart';

class PreUserScreen extends StatelessWidget {
  const PreUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('loading');
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('error'),
          );
        } else if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
