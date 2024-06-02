import 'package:flutter/material.dart';

class MatchesPage extends StatelessWidget {
  final String tournamentId;

  const MatchesPage({Key? key, required this.tournamentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Matches Page for Tournament ID: $tournamentId'),
    );
  }
}
