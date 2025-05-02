import 'package:cloud_firestore/cloud_firestore.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer une nouvelle session
  Future<void> createSession(String quizId, String codeSession) async {
    try {
      await _firestore.collection('sessions').add({
        'quizId': quizId,
        'codeSession': codeSession,
        'etatSession': 'en_attente',
        'participants': [],
        'questionActive': 0,
        'leaderboard': [],
      });
    } catch (e) {
      print("Erreur lors de la création de la session: $e");
    }
  }

  // Lancer le quiz (changer l'état de la session)
  Future<void> startQuiz(String sessionId) async {
    try {
      DocumentReference sessionRef = _firestore.collection('sessions').doc(sessionId);

      // Vérifie si le document existe
      DocumentSnapshot sessionSnapshot = await sessionRef.get();

      if (!sessionSnapshot.exists) {
        print("Erreur : La session avec l'ID $sessionId n'existe pas.");
        return;
      }

      // Si la session existe, met à jour son état
      await sessionRef.update({
        'etatSession': 'ouverte',
        'questionActive': 1, // Indiquer la première question active
      });
    } catch (e) {
      print("Erreur lors du démarrage du quiz: $e");
    }
  }

  // Marquer la session comme terminée
  Future<void> endQuiz(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'etatSession': 'fermee',
      });
    } catch (e) {
      print("Erreur lors de la fermeture de la session: $e");
    }
  }

  // Ajouter un participant à la session
  Future<void> addParticipant(String sessionId, String participantId, String username) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'participants': FieldValue.arrayUnion([
          {'idParticipant': participantId, 'username': username, 'score': 0}
        ]),
      });
    } catch (e) {
      print("Erreur lors de l'ajout du participant: $e");
    }
  }

  // Récupérer l'état de la session
  Future<String> getSessionState(String sessionId) async {
    try {
      DocumentSnapshot sessionSnapshot = await _firestore.collection('sessions').doc(sessionId).get();
      return sessionSnapshot['etatSession'];
    } catch (e) {
      print("Erreur lors de la récupération de l'état de la session: $e");
      return '';
    }
  }

  // Récupérer les participants pour afficher un leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard(String sessionId) async {
    try {
      DocumentSnapshot sessionSnapshot = await _firestore.collection('sessions').doc(sessionId).get();
      List participants = sessionSnapshot['leaderboard'];
      return participants.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print("Erreur lors de la récupération du leaderboard: $e");
      return [];
    }
  }

  // Ajouter une réponse à une question pour un participant
  Future<void> addAnswer(String sessionId, String participantId, int questionId, bool isCorrect, int timeTaken) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).collection('réponses').add({
        'idParticipant': participantId,
        'idQuestion': questionId,
        'isCorrect': isCorrect,
        'timeTaken': timeTaken,
        'score': isCorrect ? 1 : 0, // Si la réponse est correcte, score = 1
      });

      // Mettre à jour le score du participant dans la session
      await _firestore.collection('sessions').doc(sessionId).update({
        'participants': FieldValue.arrayUnion([
          {
            'idParticipant': participantId,
            'score': FieldValue.increment(isCorrect ? 1 : 0) // Incrémenter le score
          }
        ])
      });
    } catch (e) {
      print("Erreur lors de l'ajout de la réponse: $e");
    }
  }
}
