class Participant {
  String id;
  String username;
  int score;
  String sessionId;

  Participant({required this.id, required this.username, required this.sessionId, this.score = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'score': score,
      'sessionId': sessionId,
    };
  }
}
