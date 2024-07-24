import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'update_all_users_tournament_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await updateAllUsersTournamentHistory();
}
