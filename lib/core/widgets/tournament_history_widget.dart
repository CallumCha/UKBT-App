import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/auth/models/user_model.dart';

class TournamentHistoryWidget extends StatelessWidget {
  final User user;

  const TournamentHistoryWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: user.tournamentHistory.length,
      itemBuilder: (context, index) {
        final tournament = user.tournamentHistory[index];
        return ListTile(
          title: Text(tournament['tournamentName']),
          subtitle: Text('Date: ${(tournament['date'] as Timestamp).toDate().toString().split(' ')[0]}'),
          trailing: Text('Position: ${tournament['position']}'),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(tournament['tournamentName']),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${(tournament['date'] as Timestamp).toDate().toString().split(' ')[0]}'),
                      Text('Position: ${tournament['position']}'),
                      Text('Partner: ${tournament['partner']['name']}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
