import 'package:flutter/material.dart';

class RegistrationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isAdmin;
  final String ukbtno1;
  final void Function(String?) onSavedUkbtno1;
  final void Function(String?) onSavedUkbtno2;

  const RegistrationForm({
    Key? key,
    required this.formKey,
    required this.isAdmin,
    required this.ukbtno1,
    required this.onSavedUkbtno1,
    required this.onSavedUkbtno2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          if (isAdmin)
            TextFormField(
              decoration: const InputDecoration(labelText: 'Player 1 UKBT Number'),
              initialValue: ukbtno1,
              onSaved: onSavedUkbtno1,
            ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Player 2 UKBT Number'),
            onSaved: onSavedUkbtno2,
          ),
        ],
      ),
    );
  }
}
