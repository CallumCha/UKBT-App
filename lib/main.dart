import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/config/firebase_options.dart';
import 'package:ukbtapp/config/routes.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:ukbtapp/theme/app_theme.dart';
import 'package:ukbtapp/core/auth/login_screen.dart';
import 'package:ukbtapp/home/home_screen.dart';

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
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'UKBT App',
            theme: appTheme,
            initialRoute: '/',
            onGenerateRoute: Routes.generateRoute,
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
