// lib/core/auth/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ukbtapp/core/elo_calculator.dart'; // Updated import path

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
          'rankChanges': [],
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

  Future<void> updateMatchResultAndElo(String tournamentId, String poolName, String matchId, int score1, int score2) async {
    print("Starting updateMatchResultAndElo for match: $matchId");
    final matchRef = poolName == 'knockout' ? _db.collection('tournaments').doc(tournamentId).collection('knockout_matches').doc(matchId) : _db.collection('tournaments').doc(tournamentId).collection('pools').doc(poolName).collection('pool_matches').doc(matchId);
    final matchDoc = await matchRef.get();
    final matchData = matchDoc.data()!;
    print("Match data: $matchData");

    final team1Ref = _db.collection('teams').doc(matchData['team1']);
    final team2Ref = _db.collection('teams').doc(matchData['team2']);
    final team1Doc = await team1Ref.get();
    final team2Doc = await team2Ref.get();
    print("Team 1 data: ${team1Doc.data()}");
    print("Team 2 data: ${team2Doc.data()}");

    final user1Ref = _db.collection('users').doc(team1Doc['user1']);
    final user2Ref = _db.collection('users').doc(team1Doc['user2']);
    final user3Ref = _db.collection('users').doc(team2Doc['user1']);
    final user4Ref = _db.collection('users').doc(team2Doc['user2']);

    final user1Doc = await user1Ref.get();
    final user2Doc = await user2Ref.get();
    final user3Doc = await user3Ref.get();
    final user4Doc = await user4Ref.get();

    print("User 1 data: ${user1Doc.data()}");
    print("User 2 data: ${user2Doc.data()}");
    print("User 3 data: ${user3Doc.data()}");
    print("User 4 data: ${user4Doc.data()}");

    final user1Elo = user1Doc['elo'] as int;
    final user2Elo = user2Doc['elo'] as int;
    final user3Elo = user3Doc['elo'] as int;
    final user4Elo = user4Doc['elo'] as int;

    print("Initial ELOs - User1: $user1Elo, User2: $user2Elo, User3: $user3Elo, User4: $user4Elo");

    final team1Elo = (user1Elo + user2Elo) ~/ 2;
    final team2Elo = (user3Elo + user4Elo) ~/ 2;

    print("Team ELOs - Team1: $team1Elo, Team2: $team2Elo");

    final team1Won = score1 > score2;
    final eloChanges = EloCalculator.calculateEloChange(team1Elo, team2Elo, team1Won);

    print("ELO changes: $eloChanges");

    final newUser1Elo = user1Elo + eloChanges[0];
    final newUser2Elo = user2Elo + eloChanges[0];
    final newUser3Elo = user3Elo + eloChanges[1];
    final newUser4Elo = user4Elo + eloChanges[1];

    print("New ELOs - User1: $newUser1Elo, User2: $newUser2Elo, User3: $newUser3Elo, User4: $newUser4Elo");

    await matchRef.update({
      'score1': score1,
      'score2': score2,
      'completed': true,
      'winner': team1Won ? matchData['team1'] : matchData['team2'],
    });

    print("Updating user ELOs and rank changes");
    await _updateUserElo(user1Ref, newUser1Elo, eloChanges[0]);
    await _updateUserElo(user2Ref, newUser2Elo, eloChanges[0]);
    await _updateUserElo(user3Ref, newUser3Elo, eloChanges[1]);
    await _updateUserElo(user4Ref, newUser4Elo, eloChanges[1]);

    print("Finished updateMatchResultAndElo");
  }

  Future<void> _updateUserElo(DocumentReference userRef, int newElo, int eloChange) async {
    print("Starting _updateUserElo for user: ${userRef.id}");
    final userDoc = await userRef.get();
    final userData = userDoc.data() as Map<String, dynamic>;
    print("Current user data: $userData");

    List<Map<String, dynamic>> rankChanges = List<Map<String, dynamic>>.from(userData['rankChanges'] ?? []);
    print("Current rank changes: $rankChanges");

    rankChanges.insert(0, {
      'date': Timestamp.now(),
      'change': eloChange,
    });

    if (rankChanges.length > 30) {
      rankChanges = rankChanges.sublist(0, 30);
    }

    print("New rank changes: $rankChanges");
    print("New ELO: $newElo");

    await userRef.update({
      'elo': newElo,
      'rankChanges': rankChanges,
    });

    print("Finished _updateUserElo for user: ${userRef.id}");
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
