import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  final String sessionId;

  LeaderboardScreen({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🏆 Classement')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          List<dynamic> participants = snapshot.data!['participants'] ?? [];

          // Trier par score décroissant
          participants.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              var participant = participants[index];
              return ListTile(
                leading: Text(
                  participant['icon'] ?? '👤',
                  style: TextStyle(fontSize: 30),
                ),
                title: Text(participant['name'] ?? 'Anonyme'),
                trailing: Text('${participant['score']} pts'),
              );
            },
          );
        },
      ),
    );
  }
}
