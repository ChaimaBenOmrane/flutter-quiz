import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question.dart';
import '../models/quiz.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _quizzesRef = FirebaseFirestore.instance.collection('quizzes');

  // Ajouter un quiz
  Future<void> addQuiz(Quiz quiz) async {
    try {
      DocumentReference quizRef = await _quizzesRef.add({
        'title': quiz.title,
        'questions': quiz.questions.map((q) => q.toMap()).toList(),
      });

      // Mettre à jour l'ID du quiz après l'ajout
      await quizRef.update({'id': quizRef.id});
    } catch (e) {
      print("Erreur lors de l'ajout du quiz: $e");
    }
  }

  // Récupérer un quiz avec ses questions et réponses
  Future<Quiz> getQuizById(String quizId) async {
    try {
      DocumentSnapshot snapshot = await _quizzesRef.doc(quizId).get();
      if (snapshot.exists) {
        return Quiz.fromMap(snapshot.data() as Map<String, dynamic>, quizId);
      } else {
        throw "Quiz non trouvé";
      }
    } catch (e) {
      print("Erreur lors de la récupération du quiz: $e");
      rethrow;
    }
  }

  // Ajouter une question à un quiz existant
  Future<void> addQuestionToQuiz(String quizId, Question question) async {
    try {
      DocumentReference quizRef = _quizzesRef.doc(quizId);
      await quizRef.update({
        'questions': FieldValue.arrayUnion([question.toMap()])
      });
    } catch (e) {
      print("Erreur lors de l'ajout de la question: $e");
    }
  }

  // Modifier un quiz
  Future<void> updateQuiz(String quizId, Quiz quiz) async {
    try {
      DocumentReference quizRef = _quizzesRef.doc(quizId);
      await quizRef.update({
        'title': quiz.title,
        'questions': quiz.questions.map((q) => q.toMap()).toList(),
      });
    } catch (e) {
      print("Erreur lors de la mise à jour du quiz: $e");
    }
  }

  // Supprimer un quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _quizzesRef.doc(quizId).delete();
    } catch (e) {
      print("Erreur lors de la suppression du quiz: $e");
    }
  }

  // Modifier une question dans un quiz
  Future<void> updateQuestionInQuiz(String quizId, int questionIndex, Question question) async {
    try {
      DocumentReference quizRef = _quizzesRef.doc(quizId);
      DocumentSnapshot quizSnapshot = await quizRef.get();
      List<dynamic> questions = quizSnapshot['questions'];
      questions[questionIndex] = question.toMap();
      await quizRef.update({'questions': questions});
    } catch (e) {
      print("Erreur lors de la mise à jour de la question: $e");
    }
  }

  // Supprimer une question d'un quiz
  Future<void> deleteQuestionFromQuiz(String quizId, int questionIndex) async {
    try {
      DocumentReference quizRef = _quizzesRef.doc(quizId);
      DocumentSnapshot quizSnapshot = await quizRef.get();
      List<dynamic> questions = quizSnapshot['questions'];
      questions.removeAt(questionIndex);
      await quizRef.update({'questions': questions});
    } catch (e) {
      print("Erreur lors de la suppression de la question: $e");
    }
  }
}
