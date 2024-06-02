import 'package:flutter/material.dart';

class MatchResultPopup extends StatelessWidget {
  final Function(int, int) onSubmit;

  const MatchResultPopup({Key? key, required this.onSubmit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController team1Controller = TextEditingController();
    final TextEditingController team2Controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: team1Controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Team 1 Sets'),
          ),
          TextField(
            controller: team2Controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Team 2 Sets'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final team1Sets = int.parse(team1Controller.text);
              final team2Sets = int.parse(team2Controller.text);
              onSubmit(team1Sets, team2Sets);
              Navigator.of(context).pop();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
