import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:mentimeeter/models/question.dart';
import 'package:mentimeeter/models/quiz.dart';



class QuizGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _apiUrl = 'https://votre-api-ia.com/generate-quiz'; // Remplacer par l'URL de votre API d'IA
  final String _apiKey = 'votre-api-key'; // Remplacer par votre clé API

  // Générer un quiz à partir d'un document texte
  Future<Quiz> generateQuizFromDocument(String documentText, {
    String quizTitle = 'Quiz généré',
    int numberOfQuestions = 5,
    int defaultTimeLimit = 30,
  }) async {
    try {
      // Préparer la requête à l'API d'IA
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'document': documentText,
          'numberOfQuestions': numberOfQuestions,
          'format': 'json',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la génération du quiz: ${response.body}');
      }

      // Analyser la réponse
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Convertir les données en questions
      List<Question> questions = [];

      for (var item in data['questions']) {
        questions.add(Question(
          questionText: item['question'],
          options: List<String>.from(item['options']),
          correctAnswerIndex: item['correctAnswerIndex'],
          timeLimit: item['timeLimit'] ?? defaultTimeLimit,
        ));
      }

      // Créer l'objet Quiz
      final quiz = Quiz(
        id: const Uuid().v4(), // Générer un ID unique
        title: data['title'] ?? quizTitle,
        questions: questions,
      );

      return quiz;
    } catch (e) {
      throw Exception('Échec de la génération du quiz: $e');
    }
  }

  // Sauvegarder le quiz dans Firebase
  Future<String> saveQuizToFirebase(Quiz quiz, {String? userId}) async {
    try {
      // Référence à la collection de quiz
      final CollectionReference quizCollection = _firestore.collection('quizzes');

      // Ajouter des métadonnées
      final Map<String, dynamic> quizData = quiz.toMap();
      quizData['createdAt'] = FieldValue.serverTimestamp();
      quizData['createdBy'] = userId;

      // Ajouter le document à Firestore
      final DocumentReference docRef = await quizCollection.add(quizData);

      // Mettre à jour l'ID du quiz avec l'ID Firestore
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Échec de la sauvegarde du quiz dans Firebase: $e');
    }
  }

  // Générer un quiz à partir d'un document et le sauvegarder
  Future<Quiz> generateAndSaveQuiz(String documentText, {
    String quizTitle = 'Quiz généré',
    int numberOfQuestions = 5,
    String? userId,
  }) async {
    // Générer le quiz
    final Quiz quiz = await generateQuizFromDocument(
      documentText,
      quizTitle: quizTitle,
      numberOfQuestions: numberOfQuestions,
    );

    // Sauvegarder le quiz
    final String firestoreId = await saveQuizToFirebase(quiz, userId: userId);

    // Mettre à jour l'ID avec celui de Firestore
    quiz.id = firestoreId;

    return quiz;
  }
}