class Question {
  String questionText;
  List<String> options;
  int correctAnswerIndex;
  int timeLimit;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.timeLimit,
  });

  // Convertir une question en map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'timeLimit': timeLimit,
    };
  }

  // Convertir une question Firestore en modèle Question
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['questionText'],
      options: List<String>.from(map['options']),
      correctAnswerIndex: map['correctAnswerIndex'],
      timeLimit: map['timeLimit'],
    );
  }
}