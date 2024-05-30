import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserForm extends StatefulWidget {
  const AddUserForm({super.key});

  @override
  _AddUserFormState createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _namefController = TextEditingController();
  final _namelController = TextEditingController();
  final _rankController = TextEditingController();
  final _uidController = TextEditingController();
  final _ukbtnoController = TextEditingController();

  @override
  void dispose() {
    _namefController.dispose();
    _namelController.dispose();
    _rankController.dispose();
    _uidController.dispose();
    _ukbtnoController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      final newUser = {
        'namef': _namefController.text,
        'namel': _namelController.text,
        'rank': int.parse(_rankController.text),
        'uid': _uidController.text,
        'ukbtno': int.parse(_ukbtnoController.text),
      };

      await FirebaseFirestore.instance.collection('users').add(newUser);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namefController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the first name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _namelController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the last name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _rankController,
                  decoration: const InputDecoration(labelText: 'Rank'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the rank';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _uidController,
                  decoration: const InputDecoration(labelText: 'UID'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the UID';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ukbtnoController,
                  decoration: const InputDecoration(labelText: 'UKBT No.'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the UKBT number';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _addUser,
                  child: const Text('Add User'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
