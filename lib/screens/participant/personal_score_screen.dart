import 'package:flutter/material.dart';

class PersonalScoreScreen extends StatelessWidget {
  final int score;

  PersonalScoreScreen({required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Votre Score Final')),
      body: Center(
        child: Text(
          'Votre Score: $score points',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
