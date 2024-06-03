import 'package:flutter/material.dart';
import 'package:ukbtapp/core/auth/login_screen.dart';
import 'package:ukbtapp/home/home_screen.dart';
import 'package:ukbtapp/core/profile/profile_screen.dart';
import 'package:ukbtapp/core/tournaments/tournament_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/tournaments':
        return MaterialPageRoute(builder: (_) => TournamentScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
