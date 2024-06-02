import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/knockout_model.dart';

class KnockoutPage extends StatelessWidget {
  final String tournamentId;

  const KnockoutPage({Key? key, required this.tournamentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching knockout matches'));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: Text('No knockout matches data available'));
        }

        final tournamentData = snapshot.data!.data() as Map<String, dynamic>;
        final knockoutMatchesList = (tournamentData['knockoutMatches'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        final knockoutMatches = knockoutMatchesList.map((knockoutData) => KnockoutMatch.fromMap(knockoutData)).toList();

        return ListView.builder(
          itemCount: knockoutMatches.length,
          itemBuilder: (context, index) {
            final match = knockoutMatches[index];
            return ListTile(
              title: Text(
                '${match.team1['user1Name']} & ${match.team1['user2Name']} vs ${match.team2['user1Name']} & ${match.team2['user2Name']}',
              ),
              subtitle: match.result == null ? const Text('No result') : Text('Result: ${match.result?['setsTeam1']} - ${match.result?['setsTeam2']}'),
              onTap: () {
                // Handle tap to show match details or update result
              },
            );
          },
        );
      },
    );
  }
}
