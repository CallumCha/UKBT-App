import 'package:flutter/material.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomNavigationBar: BottomNavBar(x: 1),
    );
  }
}
