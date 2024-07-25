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
  DateTime _tournamentDate = DateTime.now();

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
        'date': Timestamp.fromDate(_tournamentDate),
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Tournament'),
      content: Stack(
        children: [
          SizedBox(
            width: 300,
            height: 400,
            child: SingleChildScrollView(
              child: Form(
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
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Date'),
                      readOnly: true,
                      controller: TextEditingController(
                        text: "${_tournamentDate.toLocal()}".split(' ')[0],
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _tournamentDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != _tournamentDate) {
                          setState(() {
                            _tournamentDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              color: Colors.red.withOpacity(0.7),
              padding: const EdgeInsets.all(4),
              child: const Text(
                'DEBUG',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _createTournament();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
