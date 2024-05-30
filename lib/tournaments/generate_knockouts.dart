import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ukbtapp/services/firestore.dart';

class KnockoutMatchGenerator {
  final List<Map<String, dynamic>> teams;
  final String tournamentId;
  final FirestoreService firestoreService;
  final DateTime lastGroupMatchEndTime;

  KnockoutMatchGenerator({
    required this.teams,
    required this.tournamentId,
    required this.firestoreService,
    required this.lastGroupMatchEndTime,
  });

  Future<List<Map<String, dynamic>>> generateKnockouts() async {
    List<Map<String, dynamic>> knockoutMatches = [];
    DateTime nextMatchTime = lastGroupMatchEndTime.add(const Duration(hours: 1));

    if (teams.length <= 4) {
      knockoutMatches = _generateFor4Teams(nextMatchTime);
    } else if (teams.length <= 7) {
      knockoutMatches = _generateFor5To7Teams(nextMatchTime);
    } else if (teams.length <= 10) {
      knockoutMatches = _generateFor8To10Teams(nextMatchTime);
    } else {
      knockoutMatches = _generateFor11To12Teams(nextMatchTime);
    }

    for (var match in knockoutMatches) {
      await firestoreService.addMatch(tournamentId, match);
      print('Knockout match added: $match okand');
    }

    return knockoutMatches;
  }

  List<Map<String, dynamic>> _generateFor4Teams(DateTime nextMatchTime) {
    List<Map<String, dynamic>> knockoutMatches = [];
    // Generate semi-final matches
    knockoutMatches.add(_createMatch('Semi-final', teams[0], teams[3], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));
    knockoutMatches.add(_createMatch('Semi-final', teams[1], teams[2], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate 3rd place match
    knockoutMatches.add(_createMatch(
        '3rd Place Match',
        {
          'placeholder': 'Loser of Semi-final 1'
        },
        {
          'placeholder': 'Loser of Semi-final 2'
        },
        nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate final match
    knockoutMatches.add(_createMatch(
        'Final',
        {
          'placeholder': 'Winner of Semi-final 1'
        },
        {
          'placeholder': 'Winner of Semi-final 2'
        },
        nextMatchTime));

    return knockoutMatches;
  }

  List<Map<String, dynamic>> _generateFor5To7Teams(DateTime nextMatchTime) {
    List<Map<String, dynamic>> knockoutMatches = [];
    // Generate semi-final matches
    knockoutMatches.add(_createMatch('Semi-final', teams[0], teams[3], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));
    knockoutMatches.add(_createMatch('Semi-final', teams[1], teams[2], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate 3rd place match
    knockoutMatches.add(_createMatch(
        '3rd Place Match',
        {
          'placeholder': 'Loser of Semi-final 1'
        },
        {
          'placeholder': 'Loser of Semi-final 2'
        },
        nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate final match
    knockoutMatches.add(_createMatch(
        'Final',
        {
          'placeholder': 'Winner of Semi-final 1'
        },
        {
          'placeholder': 'Winner of Semi-final 2'
        },
        nextMatchTime));

    return knockoutMatches;
  }

  List<Map<String, dynamic>> _generateFor8To10Teams(DateTime nextMatchTime) {
    List<Map<String, dynamic>> knockoutMatches = [];
    // Generate semi-final matches
    knockoutMatches.add(_createMatch('Semi-final', teams[0], teams[3], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));
    knockoutMatches.add(_createMatch('Semi-final', teams[1], teams[2], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate 3rd place match
    knockoutMatches.add(_createMatch(
        '3rd Place Match',
        {
          'placeholder': 'Loser of Semi-final 1'
        },
        {
          'placeholder': 'Loser of Semi-final 2'
        },
        nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate final match
    knockoutMatches.add(_createMatch(
        'Final',
        {
          'placeholder': 'Winner of Semi-final 1'
        },
        {
          'placeholder': 'Winner of Semi-final 2'
        },
        nextMatchTime));

    return knockoutMatches;
  }

  List<Map<String, dynamic>> _generateFor11To12Teams(DateTime nextMatchTime) {
    List<Map<String, dynamic>> knockoutMatches = [];
    // Generate semi-final matches
    knockoutMatches.add(_createMatch('Semi-final', teams[0], teams[3], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));
    knockoutMatches.add(_createMatch('Semi-final', teams[1], teams[2], nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate 3rd place match
    knockoutMatches.add(_createMatch(
        '3rd Place Match',
        {
          'placeholder': 'Loser of Semi-final 1'
        },
        {
          'placeholder': 'Loser of Semi-final 2'
        },
        nextMatchTime));
    nextMatchTime = nextMatchTime.add(const Duration(hours: 1));

    // Generate final match
    knockoutMatches.add(_createMatch(
        'Final',
        {
          'placeholder': 'Winner of Semi-final 1'
        },
        {
          'placeholder': 'Winner of Semi-final 2'
        },
        nextMatchTime));

    return knockoutMatches;
  }

  Map<String, dynamic> _createMatch(String pool, dynamic team1, dynamic team2, DateTime matchTime) {
    return {
      'pool': pool,
      'team1': team1,
      'team2': team2,
      'score': '0-0',
      'status': 'To play',
      'time': DateFormat('HH:mm a').format(matchTime),
    };
  }
}
