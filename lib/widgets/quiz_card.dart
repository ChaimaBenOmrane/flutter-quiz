import 'package:flutter/material.dart';

class QuizCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  QuizCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: 18)),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
