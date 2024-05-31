import 'package:flutter/material.dart';
import 'package:ukbtapp/core/auth/login_screen.dart';
import 'package:ukbtapp/core/user/profile_screen.dart';
import 'package:ukbtapp/core/tournament/tournament_details_screen.dart';
import 'package:ukbtapp/core/tournament/tournaments_screen.dart';
import 'package:ukbtapp/home/home_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/tournaments':
        return MaterialPageRoute(builder: (_) => TournamentsScreen());
      case '/tournamentDetails':
        final String tournamentId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournamentId: tournamentId));
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
