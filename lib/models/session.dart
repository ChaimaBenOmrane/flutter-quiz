import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String sessionCode;
  final String quizId;
  final String quizTitle;
  final Timestamp createdAt;
  final bool isStarted;
  final bool isEnded;
  final int currentQuestionIndex;
  final bool questionActive;

  Session({
    required this.sessionCode,
    required this.quizId,
    required this.quizTitle,
    required this.createdAt,
    required this.isStarted,
    required this.isEnded,
    required this.currentQuestionIndex,
    required this.questionActive,
  });

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      sessionCode: map['sessionCode'] ?? '',
      quizId: map['quizId'] ?? '',
      quizTitle: map['quizTitle'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isStarted: map['isStarted'] ?? false,
      isEnded: map['isEnded'] ?? false,
      currentQuestionIndex: map['currentQuestionIndex'] ?? -1,
      questionActive: map['questionActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionCode': sessionCode,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'createdAt': createdAt,
      'isStarted': isStarted,
      'isEnded': isEnded,
      'currentQuestionIndex': currentQuestionIndex,
      'questionActive': questionActive,
    };
  }
}
