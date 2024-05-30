import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ukbtapp/services/auth.dart';
import 'package:ukbtapp/services/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Tournaments>> getTournaments() async {
    var ref = _db.collection('tournaments');
    var snapshot = await ref.get();
    var tournaments = snapshot.docs.map((doc) {
      var data = doc.data();
      data['tournamentId'] = doc.id;
      return Tournaments.fromJson(data);
    }).toList();
    return tournaments;
  }

  Stream<Users> streamUsers() {
    return AuthService().userStream.switchMap((user) {
      if (user != null) {
        var ref = _db.collection('users').doc(user.uid);
        return ref.snapshots().map((doc) => Users.fromJson(doc.data()!));
      } else {
        return Stream.fromIterable([
          Users()
        ]);
      }
    });
  }

  Future<void> updateUserDetails(User user) {
    var ref = _db.collection('users').doc(user.uid);
    var data = {
      'uid': user.uid,
      'ukbtno': 8723, // Example value, should be dynamic
    };
    return ref.set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserByUkbtno(int ukbtno) async {
    final querySnapshot = await _db.collection('users').where('ukbtno', isEqualTo: ukbtno).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final querySnapshot = await _db.collection('users').where('uid', isEqualTo: uid).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  Future<void> addTeamToTournament(String tournamentId, Map<String, dynamic> teamData) async {
    final tournamentRef = _db.collection('tournaments').doc(tournamentId);
    final tournamentSnapshot = await tournamentRef.get();

    if (tournamentSnapshot.exists) {
      Tournaments tournament = Tournaments.fromJson(tournamentSnapshot.data()!);
      List<Map<String, dynamic>> teams = List<Map<String, dynamic>>.from(tournament.teams);
      List<Map<String, dynamic>> reserve = List<Map<String, dynamic>>.from(tournament.reserve ?? []);

      if (teams.length < 12) {
        teams.add(teamData);
        await tournamentRef.update({
          'teams': teams
        });
      } else {
        reserve.add(teamData);
        await tournamentRef.update({
          'reserve': reserve
        });
      }

      print('Team added to tournament: $teamData');
    } else {
      print('Tournament not found');
    }
  }

  Future<void> updateTeamGroup(String tournamentId, int teamIndex, String group, {required int setsWon, required int setsLost, required int pointDifference, required int placeInPool}) async {
    final tournamentRef = _db.collection('tournaments').doc(tournamentId);
    final tournamentSnapshot = await tournamentRef.get();

    if (tournamentSnapshot.exists) {
      Tournaments tournament = Tournaments.fromJson(tournamentSnapshot.data()!);
      List<Map<String, dynamic>> teams = List<Map<String, dynamic>>.from(tournament.teams);

      if (teamIndex < teams.length) {
        teams[teamIndex]['group'] = group;
        teams[teamIndex]['setsWon'] = setsWon;
        teams[teamIndex]['setsLost'] = setsLost;
        teams[teamIndex]['pointDifference'] = pointDifference;
        teams[teamIndex]['placeInPool'] = placeInPool;
        await tournamentRef.update({
          'teams': teams
        });
      } else {
        print('Team index out of range');
      }
    } else {
      print('Tournament not found');
    }
  }

  Future<List<Map<String, dynamic>>> getExistingMatches(String tournamentId) async {
    var ref = _db.collection('tournaments').doc(tournamentId).collection('matches');
    var snapshot = await ref.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addMatch(String tournamentId, Map<String, dynamic> matchData) async {
    final matchRef = _db.collection('tournaments').doc(tournamentId).collection('matches');
    //final existingMatchQuery = await matchRef.where('team1', isEqualTo: matchData['team1']).where('team2', isEqualTo: matchData['team2']).where('time', isEqualTo: matchData['time']).get();

    await matchRef.add(matchData);
  }

  Future<Map<String, dynamic>?> getMatch(String tournamentId, Map<String, dynamic> team1, Map<String, dynamic> team2, String time) async {
    final querySnapshot = await _db.collection('tournaments').doc(tournamentId).collection('matches').where('team1', isEqualTo: team1).where('team2', isEqualTo: team2).where('time', isEqualTo: time).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }
}
