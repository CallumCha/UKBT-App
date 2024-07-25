import 'package:flutter/material.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/UKBTLogo.png', width: 200, height: 200),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(FontAwesomeIcons.userNinja, color: Colors.white),
                label: const Text('Continue as Guest'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () async {
                  await authService.anonLogin();
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(FontAwesomeIcons.google, color: Colors.white),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  await authService.googleLogin();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
