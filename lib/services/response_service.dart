import 'package:cloud_firestore/cloud_firestore.dart';

class ResponseService {
  final CollectionReference sessions = FirebaseFirestore.instance.collection('sessions');

  Future<void> sendResponse(String sessionId, String participantId, String questionId, int answerIndex, int elapsedMs) async {
    final questionSnapshot = await FirebaseFirestore.instance.collection('questions').doc(questionId).get();
    final question = questionSnapshot.data() as Map<String, dynamic>;

    final correctAnswerIndex = question['correctAnswerIndex']; // champ dans question

    int score = 0;
    if (answerIndex == correctAnswerIndex) {
      score = (1000 - elapsedMs ~/ 10).clamp(0, 1000); // Score min 0 max 1000
    }

    // Enregistre la réponse
    await sessions.doc(sessionId).collection('responses').add({
      'participantId': participantId,
      'questionId': questionId,
      'answerIndex': answerIndex,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Met à jour le score du participant
    final participantRef = sessions.doc(sessionId).collection('participants').doc(participantId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(participantRef);
      if (!snapshot.exists) throw Exception("Participant not found");

      final currentScore = snapshot['score'] ?? 0;
      transaction.update(participantRef, {'score': currentScore + score});
    });
  }
}
