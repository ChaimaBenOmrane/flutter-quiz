// screens/participant/question_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionScreen extends StatelessWidget {
  final String sessionId;

  QuestionScreen({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('sessions').doc(sessionId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentQuestionId = data['currentQuestionId'];
        final status = data['status'];

        if (status == 'waiting') {
          return Center(child: Text('Attente du début du quiz...'));
        } else if (status == 'active' && currentQuestionId != null) {
          return ActiveQuestionWidget(questionId: currentQuestionId, sessionId: sessionId);
        } else if (status == 'finished') {
          return Center(child: Text('Quiz terminé !'));
        } else {
          return Center(child: Text('Question terminée, attendez la suivante...'));
        }
      },
    );
  }
}

class ActiveQuestionWidget extends StatelessWidget {
  final String questionId;
  final String sessionId;

  ActiveQuestionWidget({required this.questionId, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('questions').doc(questionId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final question = snapshot.data!.data() as Map<String, dynamic>;
        final answers = List<String>.from(question['answers']);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(question['text'], style: TextStyle(fontSize: 24)),
            ...answers.map((answer) => ElevatedButton(
              child: Text(answer),
              onPressed: () {
                // Ici appeler service pour envoyer réponse
              },
            ))
          ],
        );
      },
    );
  }
}
