import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/tournaments/models/pool_model.dart';
import 'package:ukbtapp/core/tournaments/models/team_model.dart';
import 'package:ukbtapp/core/tournaments/pool_generator.dart';

class PoolsPage extends StatefulWidget {
  final String tournamentId;

  const PoolsPage({Key? key, required this.tournamentId}) : super(key: key);

  @override
  _PoolsPageState createState() => _PoolsPageState();
}

class _PoolsPageState extends State<PoolsPage> {
  List<Pool> _pools = [];

  @override
  void initState() {
    super.initState();
    _fetchPools();
  }

  Future<void> _fetchPools() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
      if (doc.exists) {
        final tournamentData = doc.data();
        if (tournamentData != null) {
          final poolsList = (tournamentData['pools'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          final pools = poolsList.map((poolData) => Pool.fromMap(poolData)).toList();
          setState(() {
            _pools = pools;
          });
        }
      }
    } catch (e) {
      print(e); // Replace with logging framework
    }
  }

  void _showMatchResultPopup(Pool pool, int matchIndex) {
    final match = pool.matches[matchIndex];
    final team1 = match['team1'];
    final team2 = match['team2'];

    int setsTeam1 = 0;
    int setsTeam2 = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Match Result: ${team1['user1Name']} & ${team1['user2Name']} vs ${team2['user1Name']} & ${team2['user2Name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Sets Won by ${team1['user1Name']} & ${team1['user2Name']}'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setsTeam1 = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Sets Won by ${team2['user1Name']} & ${team2['user2Name']}'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setsTeam2 = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                setState(() {
                  match['result'] = {
                    'setsTeam1': setsTeam1,
                    'setsTeam2': setsTeam2,
                  };
                  PoolGenerator().updateStandings(pool, matchIndex, setsTeam1, setsTeam2);
                });
                final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
                await tournamentDoc.update({
                  'pools': _pools.map((pool) => pool.toMap()).toList(),
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pools'),
      ),
      body: _pools.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _pools.length,
              itemBuilder: (context, index) {
                final pool = _pools[index];
                return ExpansionTile(
                  title: Text(pool.name),
                  children: pool.matches.asMap().entries.map((entry) {
                    final matchIndex = entry.key;
                    final match = entry.value;
                    final team1 = match['team1'];
                    final team2 = match['team2'];
                    final result = match['result'];

                    return ListTile(
                      title: Text('${team1['user1Name']} & ${team1['user2Name']} vs ${team2['user1Name']} & ${team2['user2Name']}'),
                      subtitle: result != null ? Text('Result: ${result['setsTeam1']} - ${result['setsTeam2']}') : null,
                      onTap: () {
                        if (result == null) {
                          _showMatchResultPopup(pool, matchIndex);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
