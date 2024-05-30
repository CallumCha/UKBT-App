import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'generate_knockouts.dart';
import 'package:ukbtapp/services/firestore.dart';

class MatchGenerator {
  final List<Map<String, dynamic>> groupA;
  final List<Map<String, dynamic>> groupB;
  final List<Map<String, dynamic>> groupC;
  final Map<String, String> playerNames;
  final String tournamentId;
  final FirestoreService firestoreService;

  MatchGenerator({
    required this.groupA,
    required this.groupB,
    required this.groupC,
    required this.playerNames,
    required this.tournamentId,
    required this.firestoreService,
  });

  Future<List<Map<String, dynamic>>> generateMatches() async {
    List<Map<String, dynamic>> allMatches = [];
    List<List<Map<String, dynamic>>> groups = [
      groupA,
      groupB,
      groupC
    ];
    List<String> poolNames = [
      'A',
      'B',
      'C'
    ];

    DateTime startTime = DateTime(2024, 5, 30, 10, 0);
    for (int k = 0; k < groups.length; k++) {
      var group = groups[k];
      var poolName = poolNames[k];
      DateTime poolStartTime = startTime;

      if (group.isNotEmpty) {
        for (int i = 0; i < group.length; i++) {
          for (int j = i + 1; j < group.length; j++) {
            int refIndex = (i + j + 1) % group.length;
            allMatches.add({
              'team1': group[i],
              'team2': group[j],
              'ref': group[refIndex],
              'pool': poolName,
              'score': '0-0', // Placeholder for score, can be updated later
              'status': i == 0 && j == 1 ? 'Playing' : 'To play', // Initial status
              'time': DateFormat('HH:mm a').format(poolStartTime)
            });
            poolStartTime = poolStartTime.add(const Duration(hours: 1));
          }
        }
      }
    }

    // Sort matches by time
    allMatches.sort((a, b) => a['time'].compareTo(b['time']));

    // Get the last match end time
    DateTime lastMatchEndTime = DateFormat('HH:mm a').parse(allMatches.last['time']).add(const Duration(hours: 1));

    // Generate knockout matches
    KnockoutMatchGenerator knockoutGenerator = KnockoutMatchGenerator(
      teams: [
        ...groupA,
        ...groupB,
        ...groupC
      ],
      tournamentId: tournamentId,
      firestoreService: firestoreService,
      lastGroupMatchEndTime: lastMatchEndTime,
    );

    List<Map<String, dynamic>> knockoutMatches = await knockoutGenerator.generateKnockouts();

    allMatches.addAll(knockoutMatches);

    // Print allMatches before returning
    print(allMatches);

    return allMatches;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Playing':
        return Colors.red;
      case 'Played':
        return Colors.green;
      case 'To play':
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusCircle(String status) {
    Color color = _getStatusColor(status);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status == 'To play' ? Colors.transparent : color,
        border: Border.all(color: color),
      ),
    );
  }

  Widget _buildStatusKey() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            _buildStatusCircle('To play'),
            const SizedBox(width: 4),
            const Text('To play', style: TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            _buildStatusCircle('Playing'),
            const SizedBox(width: 4),
            const Text('Playing', style: TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            _buildStatusCircle('Played'),
            const SizedBox(width: 4),
            const Text('Played', style: TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }

  void showMatches(BuildContext context, List<Map<String, dynamic>> matches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text(
                  'Matches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusKey(),
                const SizedBox(height: 16),
                Column(
                  children: matches.map((match) {
                    return GestureDetector(
                      onTap: () {
                        // Click action can be added here in the future
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Pool ${match['pool']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusCircle(match['status']),
                                  ],
                                ),
                                Text(
                                  '${match['time'].hour}:${match['time'].minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${playerNames[match['team1']['player1']]} / ${playerNames[match['team1']['player2']]}',
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                ),
                                const Text(
                                  '0',
                                  style: TextStyle(color: Colors.white, fontSize: 24),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.grey),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${playerNames[match['team2']['player1']]} / ${playerNames[match['team2']['player2']]}',
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                ),
                                const Text(
                                  '0',
                                  style: TextStyle(color: Colors.white, fontSize: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Ref: ${playerNames[match['ref']['player1']]} / ${playerNames[match['ref']['player2']]}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
