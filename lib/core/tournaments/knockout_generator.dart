import 'package:flutter/material.dart';
import 'package:ukbtapp/core/tournaments/models/pool_model.dart';
import 'models/knockout_model.dart';

class KnockoutGenerator {
  List<KnockoutMatch> createKnockouts(List<Pool> pools) {
    List<KnockoutMatch> knockoutMatches = [];

    if (pools.length == 1) {
      // 5 teams
      final sortedTeams = _sortTeamsByStandings(pools[0].standings);
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: sortedTeams[0],
        team2: sortedTeams[3],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: sortedTeams[1],
        team2: sortedTeams[2],
      ));
    } else if (pools.length == 2) {
      // 6-8 teams
      final groupA = _sortTeamsByStandings(pools[0].standings);
      final groupB = _sortTeamsByStandings(pools[1].standings);
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: groupA[0],
        team2: groupB[1],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: groupB[0],
        team2: groupA[1],
      ));
    } else if (pools.length == 3) {
      // 9-11 teams
      final groupA = _sortTeamsByStandings(pools[0].standings);
      final groupB = _sortTeamsByStandings(pools[1].standings);
      final groupC = _sortTeamsByStandings(pools[2].standings);
      final topTeams = [
        ...groupA.take(2),
        ...groupB.take(2),
        ...groupC.take(2)
      ];

      topTeams.sort((a, b) => (b['w'] as int).compareTo(a['w'] as int));

      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[0],
        team2: topTeams[7],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[1],
        team2: topTeams[6],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[2],
        team2: topTeams[5],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[3],
        team2: topTeams[4],
      ));
    } else if (pools.length == 4) {
      // 12 teams
      final groupA = _sortTeamsByStandings(pools[0].standings);
      final groupB = _sortTeamsByStandings(pools[1].standings);
      final groupC = _sortTeamsByStandings(pools[2].standings);
      final groupD = _sortTeamsByStandings(pools[3].standings);
      final topTeams = [
        ...groupA.take(2),
        ...groupB.take(2),
        ...groupC.take(2),
        ...groupD.take(2)
      ];

      topTeams.sort((a, b) => (b['w'] as int).compareTo(a['w'] as int));

      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[0],
        team2: topTeams[7],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[1],
        team2: topTeams[6],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[2],
        team2: topTeams[5],
      ));
      knockoutMatches.add(KnockoutMatch(
        id: UniqueKey().toString(),
        team1: topTeams[3],
        team2: topTeams[4],
      ));
    }

    return knockoutMatches;
  }

  List<Map<String, dynamic>> _sortTeamsByStandings(List<Map<String, dynamic>> standings) {
    standings.sort((a, b) {
      final int winsA = a['w'] as int;
      final int winsB = b['w'] as int;
      if (winsA != winsB) {
        return winsB.compareTo(winsA);
      }
      final int setsDiffA = (a['sWon'] as int) - (a['sLost'] as int);
      final int setsDiffB = (b['sWon'] as int) - (b['sLost'] as int);
      return setsDiffB.compareTo(setsDiffA);
    });
    return standings;
  }
}
