import 'package:flutter/material.dart';

class PoolDataTable extends StatelessWidget {
  final Map<String, dynamic> poolData;

  const PoolDataTable({
    Key? key,
    required this.poolData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> teamsInPool = List<Map<String, dynamic>>.from(poolData['teams']);

    return DataTable(
      columns: [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('P1')),
        DataColumn(label: Text('P2')),
        DataColumn(label: Text('W')),
        DataColumn(label: Text('L')),
        DataColumn(label: Text('Sets')),
      ],
      rows: List<DataRow>.generate(
        teamsInPool.length,
        (index) {
          var team = teamsInPool[index];
          return DataRow(
            cells: [
              DataCell(Text((index + 1).toString())),
              DataCell(Text(team['ukbtno1'].toString())),
              DataCell(Text(team['ukbtno2'].toString())),
              DataCell(Text(team['gamesWon'].toString())),
              DataCell(Text(team['gamesLost'].toString())),
              DataCell(Text(team['sets'])),
            ],
          );
        },
      ),
    );
  }
}
