import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateAllUsersTournamentHistory() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  print('Starting updateAllUsersTournamentHistory');

  // Fetch all tournaments
  QuerySnapshot tournamentSnapshot = await firestore.collection('tournaments').get();

  for (QueryDocumentSnapshot tournamentDoc in tournamentSnapshot.docs) {
    String tournamentId = tournamentDoc.id;
    String tournamentName = tournamentDoc['name'];
    Timestamp tournamentDate = tournamentDoc['date'];

    // Fetch all knockout matches for this tournament
    QuerySnapshot knockoutMatchesSnapshot = await firestore.collection('tournaments').doc(tournamentId).collection('knockout_matches').get();

    // Check if the final match has been played
    bool finalPlayed = knockoutMatchesSnapshot.docs.any((doc) => doc['round'] == 'Final' && doc['winner'] != '');
    print('Tournament $tournamentId final played: $finalPlayed');

    if (finalPlayed) {
      // Fetch tournament document to get final_standings
      DocumentSnapshot tournamentSnapshot = await firestore.collection('tournaments').doc(tournamentId).get();
      List<dynamic> finalStandings = tournamentSnapshot['final_standings'] ?? [];
      print('Final standings for tournament $tournamentId: ${finalStandings.length}');

      if (finalStandings.isEmpty) {
        print('No final standings found for tournament $tournamentId');
        continue; // Skip to the next tournament
      }

      for (var standing in finalStandings) {
        String teamId = standing['team'];
        int position = standing['position'];
        print('Processing team $teamId at position $position');

        // Fetch team details
        DocumentSnapshot teamDoc = await firestore.collection('tournaments').doc(tournamentId).collection('teams').doc(teamId).get();

        if (!teamDoc.exists) {
          print('Team document not found for teamId: $teamId');
          continue; // Skip to the next team
        }

        String player1Id = teamDoc['player1'];
        String player2Id = teamDoc['player2'];
        print('Team $teamId - Player 1: $player1Id, Player 2: $player2Id');

        // Update tournament history for both players
        await updateUserTournamentHistory(player1Id, {
          'tournamentId': tournamentId,
          'tournamentName': tournamentName,
          'date': tournamentDate,
          'position': position,
          'partner': {
            'id': player2Id,
            'name': await getUserName(player2Id),
          },
        });

        await updateUserTournamentHistory(player2Id, {
          'tournamentId': tournamentId,
          'tournamentName': tournamentName,
          'date': tournamentDate,
          'position': position,
          'partner': {
            'id': player1Id,
            'name': await getUserName(player1Id),
          },
        });
      }
    }
  }

  print('Finished processing all tournaments');
  print('All users\' tournament history has been updated.');
}

Future<void> updateUserTournamentHistory(String userId, Map<String, dynamic> tournamentHistory) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    DocumentReference userDocRef = firestore.collection('users').doc(userId);

    // First, get the current user document
    DocumentSnapshot userDoc = await userDocRef.get();
    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      List<dynamic> currentHistory = userData?['tournamentHistory'] ?? [];

      // Check if the tournament is already in the history
      bool tournamentExists = currentHistory.any((tournament) => tournament['tournamentId'] == tournamentHistory['tournamentId']);

      if (!tournamentExists) {
        currentHistory.add(tournamentHistory);

        // Update the user document with the new history
        await userDocRef.set({
          'tournamentHistory': currentHistory,
        }, SetOptions(merge: true));

        print('Tournament history updated for user $userId');
      } else {
        print('Tournament already exists in history for user $userId');
      }
    } else {
      // If the user document doesn't exist, create it with the tournament history
      await userDocRef.set({
        'tournamentHistory': [
          tournamentHistory
        ],
      });
      print('User document created with tournament history for user $userId');
    }
  } catch (e) {
    print('Error updating tournament history for user $userId: $e');
  }
}

Future<String> getUserName(String userId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['name'] ?? 'Unknown';
    } else {
      print('User document not found for $userId');
      return 'Unknown';
    }
  } catch (e) {
    print('Error fetching user name for $userId: $e');
    return 'Error';
  }
}
