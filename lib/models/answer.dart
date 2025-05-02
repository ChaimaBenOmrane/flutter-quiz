class Answer {
  final String id;
  final String answerText;
  final bool isCorrect; // Indicateur si c'est la bonne réponse

  Answer({
    required this.id,
    required this.answerText,
    required this.isCorrect,
  });

  // Méthode pour convertir un Answer en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'answerText': answerText,
      'isCorrect': isCorrect,
    };
  }

  // Factory pour créer un Answer à partir d'un Map
  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      id: map['id'] ?? '',
      answerText: map['answerText'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }
}
