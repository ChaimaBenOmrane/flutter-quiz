import 'package:firebase_database/firebase_database.dart';
import '../models/participant.dart';

class LeaderboardService {
  final DatabaseReference _leaderboardRef = FirebaseDatabase.instance.ref('leaderboard');

  Future<void> addScore(String participantId, int score) async {
    await _leaderboardRef.child(participantId).set({
      'score': score,
    });
  }

  Future<List<Participant>> getLeaderboard() async {
    DataSnapshot snapshot = await _leaderboardRef.orderByChild('score').get();
    List<Participant> leaderboard = [];
    if (snapshot.exists) {
      var data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        leaderboard.add(Participant(
          id: key,
          username: value['username'],
          score: value['score'],
          sessionId: value['sessionId'],
        ));
      });
    }
    return leaderboard;
  }
}
