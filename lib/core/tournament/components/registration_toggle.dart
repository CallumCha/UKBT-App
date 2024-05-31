import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationToggle extends StatefulWidget {
  final String tournamentId;

  RegistrationToggle({required this.tournamentId});

  @override
  _RegistrationToggleState createState() => _RegistrationToggleState();
}

class _RegistrationToggleState extends State<RegistrationToggle> {
  bool _isRegistrationOpen = true;

  @override
  void initState() {
    super.initState();
    _fetchRegistrationStatus();
  }

  void _fetchRegistrationStatus() async {
    final doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
    setState(() {
      _isRegistrationOpen = doc.data()?['isRegistrationOpen'] ?? true;
    });
  }

  void _toggleRegistration(bool value) async {
    setState(() {
      _isRegistrationOpen = value;
    });

    await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
      'isRegistrationOpen': _isRegistrationOpen,
    });

    if (!_isRegistrationOpen) {
      _finalizePools();
    }
  }

  Future<void> _finalizePools() async {
    final tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
    if (!tournamentDoc.exists) return;

    final tournamentData = tournamentDoc.data()!;
    final List<Map<String, dynamic>> teams = List<Map<String, dynamic>>.from((tournamentData['teams'] as List).map((team) => Map<String, dynamic>.from(team)));

    teams.sort((a, b) => b['elo'].compareTo(a['elo'])); // Sort teams by elo in descending order

    final poolSize = 4;
    final numPools = (teams.length / poolSize).ceil();
    final pools = List.generate(numPools, (_) => []);

    for (var i = 0; i < teams.length; i++) {
      pools[i % numPools].add(teams[i]);
    }

    final poolCollection = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('pools');
    await poolCollection.get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });

    for (var i = 0; i < pools.length; i++) {
      await poolCollection.add({
        'teams': List<Map<String, dynamic>>.from(pools[i]),
        'matches': _generateMatches(List<Map<String, dynamic>>.from(pools[i])),
      });
    }
  }

  List<Map<String, dynamic>> _generateMatches(List<Map<String, dynamic>> teams) {
    List<Map<String, dynamic>> matches = [];
    DateTime startTime = DateTime.now();

    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matches.add({
          'team1': teams[i],
          'team2': teams[j],
          'time': startTime.add(Duration(hours: matches.length)).toIso8601String(),
          'status': 'toPlay',
        });
      }
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text('Registration Open'),
      value: _isRegistrationOpen,
      onChanged: _toggleRegistration,
    );
  }
}
