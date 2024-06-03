// lib/core/auth/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(String name, String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'elo': 1200,
          'isAdmin': false,
        });
      }
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  Future<String> createTeam(String teamName, String tournamentId, String user1Id, String user2Id) async {
    final teamRef = await _db.collection('teams').add({
      'name': teamName,
      'tournamentId': tournamentId,
      'groupId': '',
      'user1': user1Id,
      'user2': user2Id,
    });
    return teamRef.id;
  }

  Future<String> createTournament(String name, int totalRounds) async {
    final tournamentRef = await _db.collection('tournaments').add({
      'name': name,
      'stage': 'group',
      'currentRound': 1,
      'totalRounds': totalRounds,
      'knockoutStarted': false,
    });
    return tournamentRef.id;
  }

  Future<void> createGroups(String tournamentId, List<String> teamIds) async {
    final numGroups = (teamIds.length / 4).ceil();
    List<String> groupIds = [];

    for (int i = 0; i < numGroups; i++) {
      final groupRef = await _db.collection('groups').add({
        'name': 'Group ${String.fromCharCode(65 + i)}',
        'tournamentId': tournamentId,
      });
      groupIds.add(groupRef.id);
    }

    for (int i = 0; i < teamIds.length; i++) {
      final groupId = groupIds[i % numGroups];
      await _db.collection('teams').doc(teamIds[i]).update({
        'groupId': groupId
      });
    }
  }

  Future<void> createRoundRobinMatches(String tournamentId, List<String> groupIds) async {
    for (String groupId in groupIds) {
      final teamsSnapshot = await _db.collection('teams').where('groupId', isEqualTo: groupId).get();
      final teamIds = teamsSnapshot.docs.map((doc) => doc.id).toList();

      for (int i = 0; i < teamIds.length; i++) {
        for (int j = i + 1; j < teamIds.length; j++) {
          await _db.collection('matches').add({
            'tournamentId': tournamentId,
            'groupId': groupId,
            'stage': 'group',
            'round': 1,
            'team1': teamIds[i],
            'team2': teamIds[j],
            'score1': 0,
            'score2': 0,
            'completed': false,
            'date': null,
          });
        }
      }
    }
  }

  Future<void> updateMatchResultAndElo(String matchId, int score1, int score2) async {
    final matchRef = _db.collection('matches').doc(matchId);
    final matchDoc = await matchRef.get();
    final matchData = matchDoc.data()!;

    final team1Ref = _db.collection('teams').doc(matchData['team1']);
    final team2Ref = _db.collection('teams').doc(matchData['team2']);
    final team1Doc = await team1Ref.get();
    final team2Doc = await team2Ref.get();

    final user1Ref = _db.collection('users').doc(team1Doc['user1']);
    final user2Ref = _db.collection('users').doc(team1Doc['user2']);
    final user3Ref = _db.collection('users').doc(team2Doc['user1']);
    final user4Ref = _db.collection('users').doc(team2Doc['user2']);

    final user1Doc = await user1Ref.get();
    final user2Doc = await user2Ref.get();
    final user3Doc = await user3Ref.get();
    final user4Doc = await user4Ref.get();

    final user1Elo = user1Doc['elo'] as int;
    final user2Elo = user2Doc['elo'] as int;
    final user3Elo = user3Doc['elo'] as int;
    final user4Elo = user4Doc['elo'] as int;

    final team1Elo = (user1Elo + user2Elo) / 2;
    final team2Elo = (user3Elo + user4Elo) / 2;

    final team1Score = score1 > score2
        ? 1.0
        : score1 == score2
            ? 0.5
            : 0.0;
    final team2Score = score2 > score1
        ? 1.0
        : score1 == score2
            ? 0.5
            : 0.0;

    final List<double> newElo = calculateElo(team1Elo, team2Elo, team1Score, team2Score);

    final newTeam1Elo = newElo[0];
    final newTeam2Elo = newElo[1];

    final newUser1Elo = user1Elo + (newTeam1Elo - team1Elo);
    final newUser2Elo = user2Elo + (newTeam1Elo - team1Elo);
    final newUser3Elo = user3Elo + (newTeam2Elo - team2Elo);
    final newUser4Elo = user4Elo + (newTeam2Elo - team2Elo);

    await matchRef.update({
      'score1': score1,
      'score2': score2,
      'completed': true,
    });

    await user1Ref.update({
      'elo': newUser1Elo.toInt()
    });
    await user2Ref.update({
      'elo': newUser2Elo.toInt()
    });
    await user3Ref.update({
      'elo': newUser3Elo.toInt()
    });
    await user4Ref.update({
      'elo': newUser4Elo.toInt()
    });
  }

  List<double> calculateElo(double rating1, double rating2, double score1, double score2) {
    const int kFactor = 32;
    final expected1 = 1 / (1 + (10 ^ ((rating2 - rating1) / 400).toInt()));
    final expected2 = 1 / (1 + (10 ^ ((rating1 - rating2) / 400).toInt()));
    final newRating1 = rating1 + kFactor * (score1 - expected1);
    final newRating2 = rating2 + kFactor * (score2 - expected2);
    return [
      newRating1,
      newRating2
    ];
  }

  Future<void> transitionToKnockout(String tournamentId) async {
    final groupsSnapshot = await _db.collection('groups').where('tournamentId', isEqualTo: tournamentId).get();
    List<String> knockoutTeams = [];

    for (final groupDoc in groupsSnapshot.docs) {
      final groupTeamsSnapshot = await _db.collection('teams').where('groupId', isEqualTo: groupDoc.id).get();
      final groupTeams = groupTeamsSnapshot.docs
          .map((doc) => {
                'teamId': doc.id,
                'points': doc['points'] ?? 0, // Assuming there is a points field
              })
          .toList();

      groupTeams.sort((a, b) => b['points'].compareTo(a['points']));
      knockoutTeams.add(groupTeams[0]['teamId']);
      knockoutTeams.add(groupTeams[1]['teamId']);
    }

    for (int i = 0; i < knockoutTeams.length; i += 2) {
      await _db.collection('matches').add({
        'tournamentId': tournamentId,
        'stage': 'knockout',
        'round': 1,
        'team1': knockoutTeams[i],
        'team2': knockoutTeams[i + 1],
        'score1': 0,
        'score2': 0,
        'completed': false,
        'date': null,
      });
    }

    final tournamentRef = _db.collection('tournaments').doc(tournamentId);
    await tournamentRef.update({
      'stage': 'knockout',
      'knockoutStarted': true,
    });
  }

  Future<void> registerTeam(String tournamentId, String teamName, String user1Ukbtno, String user2Ukbtno) async {
    final user1Snapshot = await _db.collection('users').where('ukbtno', isEqualTo: user1Ukbtno).get();
    final user2Snapshot = await _db.collection('users').where('ukbtno', isEqualTo: user2Ukbtno).get();

    if (user1Snapshot.docs.isEmpty || user2Snapshot.docs.isEmpty) {
      throw Exception('One or both users not found');
    }

    final user1Doc = user1Snapshot.docs.first;
    final user2Doc = user2Snapshot.docs.first;

    await _db.collection('teams').add({
      'name': teamName,
      'tournamentId': tournamentId,
      'user1': user1Doc.id,
      'user2': user2Doc.id,
    });
  }

  Future<void> closeRegistration(String tournamentId) async {
    await _db.collection('tournaments').doc(tournamentId).update({
      'registrationOpen': false,
    });
  }
}
