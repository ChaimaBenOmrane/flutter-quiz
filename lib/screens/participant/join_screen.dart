import 'package:flutter/material.dart';

class JoinScreen extends StatefulWidget {
  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  void _joinSession() {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    if (code.isNotEmpty && name.isNotEmpty) {
      Navigator.pushNamed(context, '/waiting_room', arguments: {'code': code, 'name': name});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _codeController, decoration: InputDecoration(labelText: 'Code Session')),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Pseudo')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _joinSession, child: Text('Rejoindre')),
          ],
        ),
      ),
    );
  }
}
