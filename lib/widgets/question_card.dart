import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final List<String> answers;
  final Function(int) onAnswerSelected;

  QuestionCard({required this.question, required this.answers, required this.onAnswerSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(question, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          ...answers.asMap().entries.map((entry) {
            int idx = entry.key;
            String answer = entry.value;
            return ListTile(
              title: Text(answer),
              onTap: () => onAnswerSelected(idx),
            );
          }).toList(),
        ],
      ),
    );
  }
}
