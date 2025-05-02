import 'package:firebase_database/firebase_database.dart';
import '../models/participant.dart';

class ParticipantService {
  final DatabaseReference _participantRef = FirebaseDatabase.instance.ref('participants');

  Future<void> addParticipant(Participant participant) async {
    await _participantRef.child(participant.id).set(participant.toMap());
  }

  Future<List<Participant>> getParticipantsBySession(String sessionId) async {
    DataSnapshot snapshot = await _participantRef.orderByChild('sessionId').equalTo(sessionId).get();
    List<Participant> participants = [];
    if (snapshot.exists) {
      var data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        participants.add(Participant(
          id: key,
          username: value['username'],
          sessionId: value['sessionId'],
          score: value['score'],
        ));
      });
    }
    return participants;
  }
}
