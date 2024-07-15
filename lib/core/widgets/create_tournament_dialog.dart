import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTournamentDialog extends StatefulWidget {
  const CreateTournamentDialog({super.key});

  @override
  _CreateTournamentDialogState createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends State<CreateTournamentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _levelController = TextEditingController();
  final _locationController = TextEditingController();
  int _totalRounds = 3;

  Future<void> _createTournament() async {
    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance.collection('tournaments').add({
        'name': _nameController.text,
        'gender': _genderController.text,
        'level': _levelController.text,
        'location': _locationController.text,
        'stage': 'group',
        'currentRound': 1,
        'totalRounds': _totalRounds,
        'knockoutStarted': false,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Tournament'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Enter name' : null,
            ),
            TextFormField(
              controller: _genderController,
              decoration: const InputDecoration(labelText: 'Gender (Male, Female, Mixed)'),
              validator: (value) => value?.isEmpty ?? true ? 'Enter gender' : null,
            ),
            TextFormField(
              controller: _levelController,
              decoration: const InputDecoration(labelText: 'Level (1*, 2*, 3*, 4*)'),
              validator: (value) => value?.isEmpty ?? true ? 'Enter level' : null,
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (value) => value?.isEmpty ?? true ? 'Enter location' : null,
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Rounds'),
              initialValue: '3',
              onChanged: (value) {
                setState(() {
                  _totalRounds = int.tryParse(value) ?? 3;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createTournament,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
