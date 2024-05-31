import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/config/firebase_options.dart';
import 'package:ukbtapp/config/routes.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:ukbtapp/core/tournament/tournament_service.dart';
import 'package:ukbtapp/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<TournamentService>(
          create: (_) => TournamentService(),
        ),
      ],
      child: MaterialApp(
        title: 'UKBT App',
        theme: appTheme,
        initialRoute: '/',
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}
