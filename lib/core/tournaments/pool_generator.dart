import 'package:flutter/material.dart';

import 'models/pool_model.dart';
import 'models/team_model.dart';

class PoolGenerator {
  List<Pool> createPools(List<Team> teams) {
    final numTeams = teams.length;
    final pools = <Pool>[];

    if (numTeams == 5) {
      pools.add(_createPool('Group A', teams));
    } else if (numTeams == 6) {
      pools.add(_createPool('Group A', teams.sublist(0, 3)));
      pools.add(_createPool('Group B', teams.sublist(3, 6)));
    } else if (numTeams == 7) {
      pools.add(_createPool('Group A', teams.sublist(0, 4)));
      pools.add(_createPool('Group B', teams.sublist(4, 7)));
    } else if (numTeams == 8) {
      pools.add(_createPool('Group A', teams.sublist(0, 4)));
      pools.add(_createPool('Group B', teams.sublist(4, 8)));
    } else if (numTeams == 9) {
      pools.add(_createPool('Group A', teams.sublist(0, 3)));
      pools.add(_createPool('Group B', teams.sublist(3, 6)));
      pools.add(_createPool('Group C', teams.sublist(6, 9)));
    } else if (numTeams == 10) {
      pools.add(_createPool('Group A', teams.sublist(0, 5)));
      pools.add(_createPool('Group B', teams.sublist(5, 10)));
    } else if (numTeams == 11) {
      pools.add(_createPool('Group A', teams.sublist(0, 4)));
      pools.add(_createPool('Group B', teams.sublist(4, 8)));
      pools.add(_createPool('Group C', teams.sublist(8, 11)));
    } else if (numTeams == 12) {
      pools.add(_createPool('Group A', teams.sublist(0, 3)));
      pools.add(_createPool('Group B', teams.sublist(3, 6)));
      pools.add(_createPool('Group C', teams.sublist(6, 9)));
      pools.add(_createPool('Group D', teams.sublist(9, 12)));
    }

    return pools;
  }

  Pool _createPool(String name, List<Team> teams) {
    final matches = _generatePoolMatches(teams);
    final standings = _generateStandings(teams);

    return Pool(
      id: UniqueKey().toString(), // Ensure unique ID for each pool
      name: name,
      teams: teams.map((team) => team.toMap()).toList(),
      matches: matches,
      standings: standings,
      noMatches: matches.length,
    );
  }

  List<Map<String, dynamic>> _generatePoolMatches(List<Team> teams) {
    final matches = <Map<String, dynamic>>[];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matches.add({
          'team1': teams[i].toMap(),
          'team2': teams[j].toMap(),
          'result': null, // Result will be updated later
        });
      }
    }
    return matches;
  }

  List<Map<String, dynamic>> _generateStandings(List<Team> teams) {
    final standings = teams.map((team) {
      return {
        'team': team.toMap(),
        'mp': 0,
        'w': 0,
        'l': 0,
        'sWon': 0,
        'sLost': 0,
      };
    }).toList();

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

  void updateStandings(Pool pool, int matchIndex, int team1Sets, int team2Sets) {
    final match = pool.matches[matchIndex];
    final team1 = match['team1'];
    final team2 = match['team2'];

    pool.standings.forEach((standing) {
      if (standing['team']['ukbtno1'] == team1['ukbtno1'] && standing['team']['ukbtno2'] == team1['ukbtno2']) {
        standing['mp'] += 1;
        standing['sWon'] += team1Sets;
        standing['sLost'] += team2Sets;
        if (team1Sets > team2Sets) {
          standing['w'] += 1;
        } else {
          standing['l'] += 1;
        }
      } else if (standing['team']['ukbtno1'] == team2['ukbtno1'] && standing['team']['ukbtno2'] == team2['ukbtno2']) {
        standing['mp'] += 1;
        standing['sWon'] += team2Sets;
        standing['sLost'] += team1Sets;
        if (team2Sets > team1Sets) {
          standing['w'] += 1;
        } else {
          standing['l'] += 1;
        }
      }
    });

    // Sort standings
    pool.standings.sort((a, b) {
      final int winsA = a['w'] as int;
      final int winsB = b['w'] as int;
      if (winsA != winsB) {
        return winsB.compareTo(winsA);
      }
      final int setsDiffA = (a['sWon'] as int) - (a['sLost'] as int);
      final int setsDiffB = (b['sWon'] as int) - (b['sLost'] as int);
      return setsDiffB.compareTo(setsDiffA);
    });
  }
}
