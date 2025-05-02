import 'package:flutter/material.dart';

class LeaderboardEntry extends StatelessWidget {
  final String username;
  final int score;
  final int rank;

  LeaderboardEntry({required this.username, required this.score, required this.rank});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('#$rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      title: Text(username),
      trailing: Text('$score pts', style: TextStyle(fontSize: 20)),
    );
  }
}
