import 'package:flutter/material.dart';
import 'package:ukbtapp/services/firestore.dart';
import 'package:ukbtapp/services/models.dart';

class TournamentBracket extends StatefulWidget {
  final Tournaments tournament;

  const TournamentBracket({required this.tournament, super.key});

  @override
  _TournamentBracketState createState() => _TournamentBracketState();
}

class _TournamentBracketState extends State<TournamentBracket> {
  List<Map<String, dynamic>> groupA = [];
  List<Map<String, dynamic>> groupB = [];
  List<Map<String, dynamic>> groupC = [];
  Map<String, String> playerNames = {};
  List<String> playoffRounds = [];

  @override
  void initState() {
    super.initState();
    generateGroups();
  }

  Future<void> generateGroups() async {
    List<Map<String, dynamic>> teams = widget.tournament.teams;

    // Sort teams by teamRank in descending order
    teams.sort((a, b) => int.parse(b['teamRank'] ?? '0').compareTo(int.parse(a['teamRank'] ?? '0')));

    // Split teams into groups based on the number of teams
    int numTeams = teams.length;
    FirestoreService firestoreService = FirestoreService();

    if (numTeams <= 7) {
      groupA = teams;
      await updateTeamsWithGroupAndStats(groupA, 'A', firestoreService);
      playoffRounds = [
        'Semifinals',
        'Final'
      ];
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
      playoffRounds = [
        'Quarterfinals',
        'Semifinals',
        'Final'
      ];
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
      playoffRounds = [
        'Quarterfinals',
        'Semifinals',
        'Final'
      ];
    }

    // Fetch player names
    Map<String, String> names = await _fetchPlayerNames(teams);

    setState(() {
      playerNames = names;
    });
  }

  Future<void> updateTeamsWithGroupAndStats(List<Map<String, dynamic>> group, String groupName, FirestoreService firestoreService) async {
    // Sort the group by teamRank and update the place in pool
    group.sort((a, b) => int.parse(a['teamRank'] ?? '0').compareTo(int.parse(b['teamRank'] ?? '0')));
    for (int i = 0; i < group.length; i++) {
      await firestoreService.updateTeamGroup(
        widget.tournament.tournamentId,
        group.indexOf(group[i]),
        groupName,
        setsWon: group[i]['setsWon'] ?? 0,
        setsLost: group[i]['setsLost'] ?? 0,
        pointDifference: group[i]['pointDifference'] ?? 0,
        placeInPool: i + 1,
      );
    }
  }

  Future<Map<String, String>> _fetchPlayerNames(List<Map<String, dynamic>> teams) async {
    FirestoreService firestoreService = FirestoreService();
    Map<String, String> names = {};

    for (var team in teams) {
      var player1 = await firestoreService.getUserByUkbtno(int.tryParse(team['player1'] ?? '') ?? 0);
      var player2 = await firestoreService.getUserByUkbtno(int.tryParse(team['player2'] ?? '') ?? 0);

      if (player1 != null) {
        names[team['player1']] = '${player1['namef']} ${player1['namel']}';
      } else {
        names[team['player1']] = 'Unknown';
      }

      if (player2 != null) {
        names[team['player2']] = '${player2['namef']} ${player2['namel']}';
      } else {
        names[team['player2']] = 'Unknown';
      }
    }

    return names;
  }

  @override
  Widget build(BuildContext context) {
    int numberOfTabs = 1 + playoffRounds.length; // Pools + number of playoff rounds

    return DefaultTabController(
      length: numberOfTabs,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.tournament.location} Bracket'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Pools'),
              ...playoffRounds.map((round) => Tab(text: round)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildPoolsTab(),
            ...playoffRounds.map((round) => buildPlayoffTab(round)),
          ],
        ),
      ),
    );
  }

  Widget buildPoolsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (groupA.isNotEmpty) ...[
              const Text(
                'Group A',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              buildGroupTable(groupA),
            ],
            if (groupB.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Group B',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              buildGroupTable(groupB),
            ],
            if (groupC.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Group C',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              buildGroupTable(groupC),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildPlayoffTab(String round) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Match details for $round'),
          const SizedBox(height: 20),
          Text('Referee team details for $round'),
        ],
      ),
    );
  }

  Widget buildGroupTable(List<Map<String, dynamic>> group) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16.0,
        columns: const [
          DataColumn(label: Text('Place', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Player 1', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Player 2', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Team Rank', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Sets Won', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Sets Lost', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Point Difference', style: TextStyle(fontSize: 12))),
        ],
        rows: group.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> team = entry.value;
          return DataRow(cells: [
            DataCell(Text('${team['placeInPool'] ?? index + 1}.', style: const TextStyle(fontSize: 12))),
            DataCell(Text(playerNames[team['player1']] ?? 'Unknown', style: const TextStyle(fontSize: 12))),
            DataCell(Text(playerNames[team['player2']] ?? 'Unknown', style: const TextStyle(fontSize: 12))),
            DataCell(Text(team['teamRank'] ?? '0', style: const TextStyle(fontSize: 12))),
            DataCell(Text(team['setsWon']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
            DataCell(Text(team['setsLost']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
            DataCell(Text(team['pointDifference']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
          ]);
        }).toList(),
      ),
    );
  }
}
