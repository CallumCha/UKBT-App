import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/auth/models/team_model.dart';
import 'package:ukbtapp/core/widgets/pools_tab.dart'; // Import the PoolsTab widget
import 'package:ukbtapp/core/widgets/matches_tab.dart'; // Import the MatchesTab widget
// Import the FinalStandingsTab widget

class RegistrationPage extends StatefulWidget {
  final Tournament tournament;

  const RegistrationPage({super.key, required this.tournament});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  bool isAdmin = false;
  List<Team> registeredTeams = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchRegisteredTeams();
  }

  Future<void> _fetchUserData() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        isAdmin = doc.data()?['admin'] ?? false;
      });
    }
  }

  Future<void> _fetchRegisteredTeams() async {
    final snapshot = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('teams').get();
    List<Team> teams = [];
    for (var teamDoc in snapshot.docs) {
      teams.add(Team.fromDocument(teamDoc));
    }
    setState(() {
      registeredTeams = teams;
    });
  }

  Future<String?> _getUserUidByUkbtNo(String ukbtNo) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('ukbtno', isEqualTo: ukbtNo).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  void _closeRegistration() async {
    await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).update({
      'registrationOpen': false,
    });
    setState(() {
      widget.tournament.registrationOpen = false;
    });

    // Assign teams to pools
    int poolSize = 4; // Adjust pool size as necessary
    int numPools = (registeredTeams.length / poolSize).ceil();
    List<List<Team>> pools = List.generate(numPools, (_) => []);

    // Distribute teams into pools
    for (int i = 0; i < registeredTeams.length; i++) {
      pools[i % numPools].add(registeredTeams[i]);
    }

    // Create pools and matches in Firestore
    for (int i = 0; i < pools.length; i++) {
      String poolName = 'Pool ${String.fromCharCode(65 + i)}'; // Pool A, Pool B, etc.
      DocumentReference poolDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('pools').doc(poolName);

      await poolDoc.set({
        'teams': pools[i].map((team) => team.id).toList(),
        'wins': pools[i].map((team) => 0).toList(), // Initialize wins to 0
      });

      // Create matches for each pool
      for (int j = 0; j < pools[i].length; j++) {
        for (int k = j + 1; k < pools[i].length; k++) {
          await poolDoc.collection('pool_matches').add({
            'team1': pools[i][j].id,
            'team2': pools[i][k].id,
            'winner': '',
            'type': poolName,
          });
        }
      }
    }
  }

  void _registerTeam(String user1UkbtNo, String user2UkbtNo) async {
    final user1Uid = await _getUserUidByUkbtNo(user1UkbtNo);
    final user2Uid = await _getUserUidByUkbtNo(user2UkbtNo);
    if (user1Uid != null && user2Uid != null) {
      final teamRef = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('teams').add({
        'player1': user1Uid,
        'player2': user2Uid,
        'ukbtno1': user1UkbtNo,
        'ukbtno2': user2UkbtNo,
      });

      final newTeam = Team(
        id: teamRef.id,
        player1: user1Uid,
        player2: user2Uid,
        ukbtno1: user1UkbtNo,
        ukbtno2: user2UkbtNo,
      );

      setState(() {
        registeredTeams.add(newTeam);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User(s) not found')),
      );
    }
  }

  void _showSignUpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final user1Controller = TextEditingController();
        final user2Controller = TextEditingController();

        return AlertDialog(
          title: Text('Sign up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: user1Controller,
                decoration: const InputDecoration(labelText: 'Enter UKBT No for Player 1'),
              ),
              TextField(
                controller: user2Controller,
                decoration: const InputDecoration(labelText: 'Enter UKBT No for Player 2'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _registerTeam(user1Controller.text, user2Controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Sign up'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStandingsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Tournament data not available'));
        }

        final tournamentData = snapshot.data!.data() as Map<String, dynamic>;
        final finalStandings = tournamentData['final_standings'] as List<dynamic>?;
        print('Final Standings: $finalStandings'); // Add this line for debugging

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
                ),
                children: [
                  TableCell(child: Center(child: Text('#', style: TextStyle(color: Colors.grey)))),
                  TableCell(
                      child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Player 1', style: TextStyle(color: Colors.grey)),
                  )),
                  TableCell(
                      child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Player 2', style: TextStyle(color: Colors.grey)),
                  )),
                ],
              ),
              if (finalStandings != null && finalStandings.isNotEmpty) ...finalStandings.map((standing) => _buildFinalStandingRow(standing)) else ..._buildCurrentStandingsRows(),
            ],
          ),
        );
      },
    );
  }

  TableRow _buildFinalStandingRow(Map<String, dynamic> standing) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 1)),
      ),
      children: [
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getRankColor(standing['position']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${standing['position']}',
                    style: TextStyle(
                      color: standing['position'] <= 3 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: FutureBuilder<Map<String, String>>(
              future: _fetchTeamPlayerNames(standing['team']),
              builder: (context, snapshot) => Text(
                snapshot.data?['player1Name'] ?? 'Loading...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: FutureBuilder<Map<String, String>>(
              future: _fetchTeamPlayerNames(standing['team']),
              builder: (context, snapshot) => Text(
                snapshot.data?['player2Name'] ?? 'Loading...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildCurrentStandingsRows() {
    return registeredTeams.asMap().entries.map((entry) {
      int index = entry.key;
      Team team = entry.value;
      return TableRow(
        children: [
          TableCell(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getRankColor(index + 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index < 3 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: FutureBuilder<String>(
                future: _fetchUserName(team.player1),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? 'Loading...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: FutureBuilder<String>(
                future: _fetchUserName(team.player2),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? 'Loading...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.transparent;
    }
  }

  Widget _buildRankCell(int rank) {
    Color backgroundColor;
    Color textColor;

    switch (rank) {
      case 1:
        backgroundColor = Colors.amber;
        textColor = Colors.black;
        break;
      case 2:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.black;
        break;
      case 3:
        backgroundColor = Colors.brown[300]!;
        textColor = Colors.black;
        break;
      default:
        backgroundColor = Colors.transparent;
        textColor = Colors.white;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<Map<String, String>> _fetchTeamPlayerNames(String teamId) async {
    final teamSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('teams').doc(teamId).get();

    if (teamSnapshot.exists) {
      final teamData = teamSnapshot.data() as Map<String, dynamic>;
      final player1Name = await _fetchUserName(teamData['player1']);
      final player2Name = await _fetchUserName(teamData['player2']);

      return {
        'player1Name': player1Name,
        'player2Name': player2Name,
      };
    }
    return {
      'player1Name': 'Unknown',
      'player2Name': 'Unknown',
    };
  }

  Future<String> _fetchUserName(String userId) async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      return userData['name'] ?? 'No name';
    }
    return 'No name';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildTournamentDetails(),
          ),
          if (widget.tournament.registrationOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _showSignUpDialog,
                child: Text('Sign up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'Standings'),
                      Tab(text: 'Pools'),
                      Tab(text: 'Matches'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade800),
                              bottom: BorderSide(color: Colors.grey.shade800),
                            ),
                          ),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                                ),
                                children: [
                                  TableCell(child: Center(child: Text('#', style: TextStyle(color: Colors.grey)))),
                                  TableCell(child: Text('Player 1', style: TextStyle(color: Colors.grey))),
                                  TableCell(child: Text('Player 2', style: TextStyle(color: Colors.grey))),
                                ],
                              ),
                              ..._buildCurrentStandingsRows(),
                            ],
                          ),
                        ),
                        PoolsTab(tournamentId: widget.tournament.id),
                        MatchesTab(tournamentId: widget.tournament.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin && widget.tournament.registrationOpen)
            ElevatedButton(
              onPressed: _closeRegistration,
              child: Text('Close Registration'),
            ),
        ],
      ),
    );
  }

  Widget _buildTournamentDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender: ${widget.tournament.gender}'),
          Text('Level: ${widget.tournament.level}'),
          Text('Location: ${widget.tournament.location}'),
        ],
      ),
    );
  }
}
