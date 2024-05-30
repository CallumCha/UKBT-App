import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ukbtapp/services/firestore.dart';
import 'package:ukbtapp/tournaments/match_generator.dart';
import 'package:ukbtapp/tournaments/register_popup.dart';
import 'generate_knockouts.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;
  final String location;
  final String level;
  final String gender;
  final String date;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> reserves;

  const TournamentDetailsScreen({
    super.key,
    required this.tournamentId,
    required this.location,
    required this.level,
    required this.gender,
    required this.date,
    required this.teams,
    required this.reserves,
  });

  @override
  _TournamentDetailsScreenState createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  int? currentUserUkbtno;
  bool _registrationConfirmed = false;
  List<Map<String, dynamic>> groupA = [];
  List<Map<String, dynamic>> groupB = [];
  List<Map<String, dynamic>> groupC = [];
  Map<String, String> playerNames = {};
  List<Map<String, dynamic>> matches = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    generateGroups();
  }

  Future<void> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      final userDetails = await firestoreService.getUserByUid(user.uid);
      setState(() {
        currentUserUkbtno = userDetails?['ukbtno'];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPlayers(List<Map<String, dynamic>> list) async {
    final firestoreService = FirestoreService();
    List<Map<String, dynamic>> players = [];

    for (var team in list) {
      if (team.containsKey('player1') && team.containsKey('player2')) {
        final player1 = await firestoreService.getUserByUkbtno(int.parse(team['player1']));
        final player2 = await firestoreService.getUserByUkbtno(int.parse(team['player2']));

        players.add({
          'player1': player1 != null ? '${player1['namef'][0]}. ${player1['namel']}' : 'Unknown',
          'player2': player2 != null ? '${player2['namef'][0]}. ${player2['namel']}' : 'Unknown',
          'teamRank': team['teamRank'] ?? 'Unknown'
        });
      }
    }
    return players;
  }

  Future<Map<String, String>> _fetchPlayerNames(List<Map<String, dynamic>> teams) async {
    FirestoreService firestoreService = FirestoreService();
    Map<String, String> names = {};

    for (var team in teams) {
      var player1 = await firestoreService.getUserByUkbtno(int.tryParse(team['player1'] ?? '') ?? 0);
      var player2 = await firestoreService.getUserByUkbtno(int.tryParse(team['player2'] ?? '') ?? 0);

      if (player1 != null) {
        names[team['player1']] = '${player1['namef'][0]}. ${player1['namel']}';
      } else {
        names[team['player1']] = 'Unknown';
      }

      if (player2 != null) {
        names[team['player2']] = '${player2['namef'][0]}. ${player2['namel']}';
      } else {
        names[team['player2']] = 'Unknown';
      }
    }

    return names;
  }

  void _showRegistrationPopup(BuildContext context) {
    if (currentUserUkbtno != null) {
      showDialog(
        context: context,
        builder: (context) {
          return RegisterPopup(
            currentUserUkbtno: currentUserUkbtno!,
            tournamentId: widget.tournamentId, // Use tournamentId
            onRegistrationConfirmed: () {
              setState(() {
                _registrationConfirmed = true;
                // Refresh teams data or handle state update if needed
              });
            },
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in or UKBT number not found')),
      );
    }
  }

  Future<void> generateGroups() async {
    List<Map<String, dynamic>> teams = widget.teams;

    // Sort teams by teamRank in descending order
    teams.sort((a, b) => int.parse(b['teamRank'] ?? '0').compareTo(int.parse(a['teamRank'] ?? '0')));

    // Split teams into groups based on the number of teams
    int numTeams = teams.length;
    FirestoreService firestoreService = FirestoreService();

    if (numTeams <= 5) {
      groupA = teams;
      await updateTeamsWithGroupAndStats(groupA, 'A', firestoreService);
    } else if (numTeams <= 10) {
      for (int i = 0; i < teams.length; i++) {
        if (i % 2 == 0) {
          groupA.add(teams[i]);
        } else {
          groupB.add(teams[i]);
        }
      }
      await updateTeamsWithGroupAndStats(groupA, 'A', firestoreService);
      await updateTeamsWithGroupAndStats(groupB, 'B', firestoreService);
    } else if (numTeams <= 12) {
      for (int i = 0; i < teams.length; i++) {
        if (i % 3 == 0) {
          groupA.add(teams[i]);
        } else if (i % 3 == 1) {
          groupB.add(teams[i]);
        } else {
          groupC.add(teams[i]);
        }
      }
      await updateTeamsWithGroupAndStats(groupA, 'A', firestoreService);
      await updateTeamsWithGroupAndStats(groupB, 'B', firestoreService);
      await updateTeamsWithGroupAndStats(groupC, 'C', firestoreService);
    }

    // Fetch player names
    Map<String, String> names = await _fetchPlayerNames(teams);

    setState(() {
      playerNames = names;
      print('Groups generated and set state updated.');
    });
  }

  Future<void> updateTeamsWithGroupAndStats(List<Map<String, dynamic>> group, String groupName, FirestoreService firestoreService) async {
    // Sort the group by setsWon and if all are zero, sort by teamRank
    group.sort((a, b) {
      int setsWonA = a['setsWon'] ?? 0;
      int setsWonB = b['setsWon'] ?? 0;
      if (setsWonA == setsWonB) {
        return int.parse(a['teamRank'] ?? '0').compareTo(int.parse(b['teamRank'] ?? '0'));
      }
      return setsWonB.compareTo(setsWonA);
    });

    for (int i = 0; i < group.length; i++) {
      group[i]['placeInPool'] = i + 1;
      await firestoreService.updateTeamGroup(
        widget.tournamentId,
        group.indexOf(group[i]),
        groupName,
        setsWon: group[i]['setsWon'] ?? 0,
        setsLost: group[i]['setsLost'] ?? 0,
        pointDifference: group[i]['pointDifference'] ?? 0,
        placeInPool: group[i]['placeInPool'],
      );
    }
  }

  void generateMatches() async {
    final matchGenerator = MatchGenerator(
      groupA: groupA,
      groupB: groupB,
      groupC: groupC,
      playerNames: playerNames,
      tournamentId: widget.tournamentId,
      firestoreService: FirestoreService(),
    );

    matches = await matchGenerator.generateMatches();

    // Sort matches by time in ascending order
    matches.sort((a, b) => a['time'].compareTo(b['time']));

    // Upload group matches to Firestore
    final firestoreService = FirestoreService();
    for (var match in matches) {
      var existingMatch = await firestoreService.getMatch(widget.tournamentId, match['team1'], match['team2'], match['time']);
      if (existingMatch == null) {
        await firestoreService.addMatch(widget.tournamentId, match);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allGroups = [
      ...groupA,
      ...groupB,
      ...groupC
    ];
    allGroups.sort((a, b) => int.parse(a['teamRank'] ?? '0').compareTo(int.parse(b['teamRank'] ?? '0')));

    if (_selectedTabIndex == 1 && matches.isEmpty) {
      generateMatches();
    }

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(right: 0.0), // Adjust this value if needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${widget.location} ${widget.level} ${widget.gender}'),
              Text(
                widget.date,
                style: const TextStyle(fontSize: 14), // Smaller font for the date
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('Pools', 0),
                _buildTabButton('Matches', 1),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0), // Add padding to prevent content under the button
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (_selectedTabIndex == 0)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchPlayers(widget.teams),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(child: Text('Error loading players'));
                          }

                          final players = snapshot.data ?? [];

                          return Column(
                            children: [
                              _buildGroupTables(),
                              if (_registrationConfirmed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Container(
                                    color: Colors.green,
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'Registration confirmed!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    if (_selectedTabIndex == 1)
                      Column(
                        children: [
                          _buildStatusKey(), // Add status key here
                          for (var match in matches) _buildMatchCard(match),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (_selectedTabIndex == 0)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchPlayers(widget.reserves),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(child: Text('Error loading reserve players'));
                          }

                          final reservePlayers = snapshot.data ?? [];

                          return ExpansionTile(
                            title: Text('Reserve List (${widget.reserves.length})'),
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 16.0,
                                  columns: const [
                                    DataColumn(label: Text('Player 1', style: TextStyle(fontSize: 12))),
                                    DataColumn(label: Text('Player 2', style: TextStyle(fontSize: 12))),
                                    DataColumn(label: Text('Team Rank', style: TextStyle(fontSize: 12))),
                                  ],
                                  rows: reservePlayers.map((player) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 100, // Set a fixed width
                                            child: Text(
                                              player['player1'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 100, // Set a fixed width
                                            child: Text(
                                              player['player2'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(player['teamRank'].toString())),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(20, 19, 23, 0),
                  Color.fromRGBO(20, 19, 23, 1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () => _showRegistrationPopup(context),
                child: const Text('Register'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _selectedTabIndex == index ? Colors.yellow : Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: _selectedTabIndex == index ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTables() {
    return Column(
      children: [
        if (groupA.isNotEmpty) _buildGroupTable('Group A', groupA),
        if (groupB.isNotEmpty) _buildGroupTable('Group B', groupB),
        if (groupC.isNotEmpty) _buildGroupTable('Group C', groupC),
      ],
    );
  }

  Widget _buildGroupTable(String groupName, List<Map<String, dynamic>> group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            groupName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width, // Full width of the screen
          child: DataTable(
            columnSpacing: 16.0,
            headingRowColor: WidgetStateColor.resolveWith((states) => Colors.grey.shade800), // Slightly lighter background for the header row
            headingRowHeight: 40.0, // Smaller vertical padding for the header row
            columns: const [
              DataColumn(
                  label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '#',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )),
              DataColumn(
                  label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Player 1',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )),
              DataColumn(
                  label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Player 2',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )),
              DataColumn(
                  label: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'MP',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )), // Matches Played
              DataColumn(
                  label: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'G',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )), // Games (Sets) Won:Lost
              DataColumn(
                  label: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'PTS',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )), // Points
            ],
            rows: group.map((team) {
              return DataRow(
                cells: [
                  DataCell(Align(alignment: Alignment.centerLeft, child: Text(team['placeInPool'].toString(), style: const TextStyle(fontSize: 12)))),
                  DataCell(Align(alignment: Alignment.centerLeft, child: Text(playerNames[team['player1']] ?? 'Unknown', style: const TextStyle(fontSize: 12)))),
                  DataCell(Align(alignment: Alignment.centerLeft, child: Text(playerNames[team['player2']] ?? 'Unknown', style: const TextStyle(fontSize: 12)))),
                  DataCell(Align(alignment: Alignment.centerRight, child: Text(team['matchesPlayed'].toString(), style: const TextStyle(fontSize: 12)))),
                  DataCell(Align(alignment: Alignment.centerRight, child: Text('${team['setsWon']}:${team['setsLost']}', style: const TextStyle(fontSize: 12)))),
                  DataCell(Align(alignment: Alignment.centerRight, child: Text(team['points'].toString(), style: const TextStyle(fontSize: 12)))),
                ],
              );
            }).toList(),
          ),
        ),
      ],
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

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final String matchTime = match['time']; // Time is already a formatted string
    final team1 = match['team1'];
    final team2 = match['team2'];
    final ref = match['ref'];

    String player1Name = team1 != null && team1['player1'] != null ? playerNames[team1['player1']] ?? 'Unknown' : 'Unknown';
    String player2Name = team1 != null && team1['player2'] != null ? playerNames[team1['player2']] ?? 'Unknown' : 'Unknown';
    String player3Name = team2 != null && team2['player1'] != null ? playerNames[team2['player1']] ?? 'Unknown' : 'Unknown';
    String player4Name = team2 != null && team2['player2'] != null ? playerNames[team2['player2']] ?? 'Unknown' : 'Unknown';
    String ref1Name = ref != null && ref['player1'] != null ? playerNames[ref['player1']] ?? 'Unknown' : 'Unknown';
    String ref2Name = ref != null && ref['player2'] != null ? playerNames[ref['player2']] ?? 'Unknown' : 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16.0),
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
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusCircle(match['status']),
                    ],
                  ),
                  Text(
                    matchTime, // Display the time string
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$player1Name / $player2Name',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${match['score1'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$player3Name / $player4Name',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${match['score2'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Ref: $ref1Name / $ref2Name',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
