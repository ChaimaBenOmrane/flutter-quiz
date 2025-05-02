// screens/participant/result_question_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultQuestionScreen extends StatelessWidget {
  final String questionId;

  ResultQuestionScreen({required this.questionId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('questions').doc(questionId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final question = snapshot.data!.data() as Map<String, dynamic>;
        final correctAnswerIndex = question['correctAnswerIndex'];
        final answers = List<String>.from(question['answers']);

        return Column(
          children: [
            Text('Bonne réponse:', style: TextStyle(fontSize: 20)),
            Text(answers[correctAnswerIndex], style: TextStyle(fontSize: 30, color: Colors.green)),
          ],
        );
      },
    );
  }
}
