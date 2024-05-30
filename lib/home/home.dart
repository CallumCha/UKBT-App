import 'package:flutter/material.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('About'),
          onPressed: () => Navigator.pushNamed(context, '/rank'),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(x: 0),
    );
  }
}
