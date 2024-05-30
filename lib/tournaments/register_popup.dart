import 'package:flutter/material.dart';
import 'package:ukbtapp/services/firestore.dart';

class RegisterPopup extends StatefulWidget {
  final int currentUserUkbtno;
  final String tournamentId;
  final VoidCallback onRegistrationConfirmed;

  const RegisterPopup({
    super.key,
    required this.currentUserUkbtno,
    required this.tournamentId,
    required this.onRegistrationConfirmed,
  });

  @override
  _RegisterPopupState createState() => _RegisterPopupState();
}

class _RegisterPopupState extends State<RegisterPopup> {
  final _formKey = GlobalKey<FormState>();
  final _playerTwoUkbtnoController = TextEditingController();

  @override
  void dispose() {
    _playerTwoUkbtnoController.dispose();
    super.dispose();
  }

  Future<void> _confirmRegistration() async {
    if (_formKey.currentState!.validate()) {
      final firestoreService = FirestoreService();
      final playerTwoUkbtno = int.parse(_playerTwoUkbtnoController.text);

      final playerOne = await firestoreService.getUserByUkbtno(widget.currentUserUkbtno);
      final playerTwo = await firestoreService.getUserByUkbtno(playerTwoUkbtno);

      if (playerOne != null && playerTwo != null) {
        final teamRank = ((playerOne['rank'] + playerTwo['rank']) / 2).round().toString();

        final teamData = {
          'player1': widget.currentUserUkbtno.toString(),
          'player2': playerTwoUkbtno.toString(),
          'teamRank': teamRank,
        };

        try {
          await firestoreService.addTeamToTournament(widget.tournamentId, teamData);
          print('Registration successful: $teamData');
          widget.onRegistrationConfirmed();
          Navigator.of(context).pop(); // Close the popup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team registered successfully')),
          );
        } catch (error) {
          print('Failed to register team: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to register team')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player not found')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register for Tournament'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: widget.currentUserUkbtno.toString(),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Player 1 UKBT No.'),
            ),
            TextFormField(
              controller: _playerTwoUkbtnoController,
              decoration: const InputDecoration(labelText: 'Player 2 UKBT No.'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Player 2 UKBT No.';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirmRegistration,
          child: const Text('Confirm Registration'),
        ),
      ],
    );
  }
}
