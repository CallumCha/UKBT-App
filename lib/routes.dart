import 'package:ukbtapp/preuser/preuser.dart';
import 'package:ukbtapp/home/home.dart';
import 'package:ukbtapp/login/login.dart';
import 'package:ukbtapp/profile/profile.dart';
import 'package:ukbtapp/rank/rank.dart';
import 'package:ukbtapp/tournaments/tournaments.dart';

var appRoutes = {
  '/': (context) => const PreUserScreen(),
  '/home': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/rank': (context) => const RankScreen(),
  '/tournaments': (context) => const TournamentsScreen(),
};
