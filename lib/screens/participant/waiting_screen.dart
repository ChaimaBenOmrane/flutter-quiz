import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> joinSession(String sessionCode, String username) async {
  final sessionSnapshot = await FirebaseFirestore.instance
      .collection('sessions')
      .where('code', isEqualTo: sessionCode)
      .get();

  if (sessionSnapshot.docs.isNotEmpty) {
    final sessionId = sessionSnapshot.docs.first.id;
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('participants')
        .add({
      'username': username,
      'score': 0,
    });
    return true;
  } else {
    return false;
  }
}
