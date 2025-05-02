// screens/admin/control_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ControlQuizScreen extends StatelessWidget {
  final String sessionId;

  ControlQuizScreen({required this.sessionId});

  void openQuestion(String questionId) async {
    await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
      'currentQuestionId': questionId,
      'status': 'active',
    });
  }

  void closeQuestion() async {
    await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
      'status': 'closed',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contrôle du Quiz')),
      body: Column(
        children: [
          ElevatedButton(
            child: Text('Fermer la question'),
            onPressed: closeQuestion,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('questions').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final questions = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(q['text']),
                      trailing: ElevatedButton(
                        child: Text('Ouvrir'),
                        onPressed: () => openQuestion(questions[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
