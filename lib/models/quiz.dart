import 'question.dart';
class Quiz {
  String id;
  String title;
  List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
  });

  // Convertir un quiz en map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  // Convertir un quiz Firestore en modèle Quiz
  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    return Quiz(
      id: id,
      title: map['title'],
      questions: List<Question>.from(
        map['questions'].map((question) => Question.fromMap(question)),
      ),
    );
  }
}