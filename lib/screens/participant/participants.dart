import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:mentimeeter/models/question.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'quiz_question_screen.dart';

class ParticipantScreen extends StatefulWidget {
  @override
  _ParticipantScreenState createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController sessionCodeController = TextEditingController();

  String? participantId;
  String? participantName;
  String? sessionCode;
  bool joinedSession = false;
  bool waitingForQuiz = true;
  bool quizEnded = false;

  int currentQuestionIndex = -1;
  Question? currentQuestion;
  bool questionActive = false;
  int? selectedAnswerIndex;
  bool hasAnswered = false;
  bool? isAnswerCorrect;
  int remainingTime = 0;
  Timer? timerSubscription;
  int score = 0;
  int rank = 0;

  final _uuid = Uuid();
  StreamSubscription? _sessionSubscription;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  bool isScanning = false;

  @override
  void dispose() {
    nameController.dispose();
    sessionCodeController.dispose();
    _sessionSubscription?.cancel();
    timerSubscription?.cancel();
    qrController?.dispose();
    super.dispose();
  }

  Future<void> _joinSession(String sessionCodeInput) async {
    if (nameController.text.isEmpty || sessionCodeInput.isEmpty) {
      _showError('Veuillez entrer votre nom et le code de session');
      return;
    }

    participantId = _uuid.v4();
    participantName = nameController.text.trim();
    sessionCode = sessionCodeInput.trim();

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
              SizedBox(height: 15),
              Text('Connexion en cours...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );

    try {
      // Check if the session exists
      DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionCode)
          .get();

      // Fermer le dialogue de chargement
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!sessionDoc.exists) {
        _showError('Session introuvable');
        return;
      }

      // Check if the session has already ended
      bool isEnded = (sessionDoc.data() as Map<String, dynamic>)['isEnded'] ?? false;
      if (isEnded) {
        _showError('Cette session est déjà terminée');
        return;
      }

      // Add participant to the "participants" subcollection
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionCode)
          .collection('participants')
          .doc(participantId)
          .set({
        'id': participantId,
        'name': participantName,
        'score': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        joinedSession = true;
        waitingForQuiz = !((sessionDoc.data() as Map<String, dynamic>)['isStarted'] ?? false);
      });

      // Listen for session changes
      _listenToSession();

      // Animation de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez rejoint la session avec succès!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showError('Erreur lors de la connexion: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _listenToSession() {
    _sessionSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionCode)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _showError('La session a été supprimée');
        _exitSession();
        return;
      }

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      bool isStarted = data['isStarted'] ?? false;
      bool isEnded = data['isEnded'] ?? false;
      int newQuestionIndex = data['currentQuestionIndex'] ?? -1;
      bool newQuestionActive = data['questionActive'] ?? false;

      if (isEnded && !quizEnded) {
        _handleQuizEnded();
        return;
      }

      if (isStarted && waitingForQuiz) {
        setState(() {
          waitingForQuiz = false;
        });
      }

      if (newQuestionIndex != currentQuestionIndex || newQuestionActive != questionActive) {
        _handleQuestionChange(newQuestionIndex, newQuestionActive);
      }
    });
  }

  Future<void> _handleQuestionChange(int newQuestionIndex, bool newQuestionActive) async {
    // Reset for new question
    if (newQuestionIndex != currentQuestionIndex) {
      setState(() {
        selectedAnswerIndex = null;
        hasAnswered = false;
        isAnswerCorrect = null;
      });

      // Load question data
      if (newQuestionIndex >= 0) {
        try {
          DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
              .collection('sessions')
              .doc(sessionCode)
              .get();

          String quizId = (sessionDoc.data() as Map<String, dynamic>)['quizId'];

          DocumentSnapshot quizDoc = await FirebaseFirestore.instance
              .collection('quizzes')
              .doc(quizId)
              .get();

          if (quizDoc.exists) {
            Map<String, dynamic> quizData = quizDoc.data() as Map<String, dynamic>;
            if (quizData.containsKey('questions') && quizData['questions'] is List) {
              List<dynamic> questionsData = quizData['questions'];

              if (newQuestionIndex < questionsData.length) {
                Map<String, dynamic> questionData = questionsData[newQuestionIndex];

                Question question = Question(
                  questionText: questionData['questionText'],
                  options: List<String>.from(questionData['answers'].map((answer) => answer['text'])),
                  correctAnswerIndex: _findCorrectAnswerIndex(questionData['answers']),
                  timeLimit: questionData['duration'],
                );

                setState(() {
                  currentQuestionIndex = newQuestionIndex;
                  currentQuestion = question;
                });
              }
            }
          }
        } catch (e) {
          print('Error loading question: $e');
        }
      }
    }

    // Question started or ended
    if (questionActive != newQuestionActive) {
      setState(() {
        questionActive = newQuestionActive;
      });

      if (newQuestionActive) {
        _startQuestionTimer();
      }
    }
  }

  int _findCorrectAnswerIndex(List<dynamic> answers) {
    for (int i = 0; i < answers.length; i++) {
      if (answers[i]['isCorrect'] == true) {
        return i;
      }
    }
    return 0;
  }

  void _startQuestionTimer() {
    if (currentQuestion == null) return;

    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionCode)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Timestamp? endTimeStamp = data['questionEndTime'];

        if (endTimeStamp != null) {
          DateTime endTime = endTimeStamp.toDate();
          DateTime now = DateTime.now();
          int secondsRemaining = endTime.difference(now).inSeconds;

          if (secondsRemaining > 0) {
            setState(() {
              remainingTime = secondsRemaining;
            });

            timerSubscription?.cancel();
            timerSubscription = Timer.periodic(Duration(seconds: 1), (timer) {
              setState(() {
                if (remainingTime > 0) {
                  remainingTime--;
                } else {
                  timer.cancel();
                }
              });
            });
          }
        }
      }
    });
  }

  Future<void> _submitAnswer(int answerIndex) async {
    if (!questionActive || hasAnswered || currentQuestion == null) return;

    int correctIndex = currentQuestion!.correctAnswerIndex;
    bool correct = answerIndex == correctIndex;

    int timePoints = remainingTime;
    int answerPoints = correct ? 1000 + timePoints * 10 : 0;

    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionCode)
          .collection('answers')
          .add({
        'participantId': participantId,
        'participantName': participantName,
        'questionIndex': currentQuestionIndex,
        'answerIndex': answerIndex,
        'isCorrect': correct,
        'timeRemaining': remainingTime,
        'timestamp': FieldValue.serverTimestamp(),
      });

      DocumentReference participantRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionCode)
          .collection('participants')
          .doc(participantId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot participantDoc = await transaction.get(participantRef);
        if (participantDoc.exists) {
          int currentScore = (participantDoc.data() as Map<String, dynamic>)['score'] ?? 0;
          transaction.update(participantRef, {'score': currentScore + answerPoints});
        }
      });

      setState(() {
        hasAnswered = true;
        selectedAnswerIndex = answerIndex;
        isAnswerCorrect = correct;
        score += answerPoints;
      });

      _showAnswerFeedback(correct);

    } catch (e) {
      print('Error submitting answer: $e');
      _showError('Erreur lors de l\'envoi de la réponse');
    }
  }

  void _showAnswerFeedback(bool correct) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: correct ? Colors.green[50] : Colors.red[50],
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  correct ? 'Correct!' : 'Incorrect!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: correct ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: correct ? Colors.green[100] : Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    correct ? Icons.check_circle : Icons.cancel,
                    color: correct ? Colors.green : Colors.red,
                    size: 60,
                  ),
                ),
                SizedBox(height: 20),
                if (correct)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      '+ ${1000 + remainingTime * 10} points!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                if (!correct && currentQuestion != null)
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      'La bonne réponse était:\n${currentQuestion!.options[currentQuestion!.correctAnswerIndex]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleQuizEnded() async {
    timerSubscription?.cancel();

    QuerySnapshot participantsSnapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionCode)
        .collection('participants')
        .orderBy('score', descending: true)
        .get();

    int participantRank = 0;
    for (int i = 0; i < participantsSnapshot.docs.length; i++) {
      if (participantsSnapshot.docs[i].id == participantId) {
        participantRank = i + 1;
        break;
      }
    }

    setState(() {
      quizEnded = true;
      rank = participantRank;
    });
  }

  void _exitSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Quitter la session?'),
        content: Text('Êtes-vous sûr de vouloir quitter la session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[800]),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sessionSubscription?.cancel();
              timerSubscription?.cancel();
              setState(() {
                joinedSession = false;
                waitingForQuiz = true;
                quizEnded = false;
                currentQuestionIndex = -1;
                questionActive = false;
                score = 0;
              });
            },
            child: Text('Quitter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _startQRScan() {
    setState(() {
      isScanning = true;
    });
  }

  void _stopQRScan() {
    qrController?.dispose();
    setState(() {
      isScanning = false;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.qrController = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        _stopQRScan();
        sessionCodeController.text = scanData.code!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Code scanné: ${scanData.code}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          joinedSession ? 'Quiz en cours' : 'Rejoindre une session',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF5E76F2),  // Bleu plus moderne
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          if (joinedSession)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _exitSession,
              tooltip: 'Quitter la session',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF2FF), Colors.white],
          ),
        ),
        child: joinedSession ?
        // Pass to the QuizScreen when joined
        QuizScreen(
          participantName: participantName,
          score: score,
          currentQuestion: currentQuestion,
          questionActive: questionActive,
          hasAnswered: hasAnswered,
          selectedAnswerIndex: selectedAnswerIndex,
          remainingTime: remainingTime,
          isAnswerCorrect: isAnswerCorrect,
          quizEnded: quizEnded,
          rank: rank,
          onSubmitAnswer: _submitAnswer,
          onExit: _exitSession,
        )
            : (isScanning ? _buildQRScanScreen() : JoinScreen(
          nameController: nameController,
          sessionCodeController: sessionCodeController,
          onJoin: _joinSession,
          onScanQR: _startQRScan,
        )),
      ),
    );
  }

  Widget _buildQRScanScreen() {
    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Color(0xFF5E76F2),
            borderRadius: 20,
            borderLength: 40,
            borderWidth: 12,
            cutOutSize: MediaQuery.of(context).size.width * 0.8,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Scannez le QR code de la session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _stopQRScan,
                  icon: Icon(Icons.arrow_back),
                  label: Text('Retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5E76F2),
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Join Screen widget
class JoinScreen extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController sessionCodeController;
  final Function(String) onJoin;
  final VoidCallback onScanQR;

  const JoinScreen({
    Key? key,
    required this.nameController,
    required this.sessionCodeController,
    required this.onJoin,
    required this.onScanQR,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo ou illustration
            Container(
              height: 180,
              margin: EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/quiz_logo.png',  // Remplacez par votre logo
                  height: 140,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.quiz,
                    size: 100,
                    color: Color(0xFF5E76F2),
                  ),
                ),
              ),
            ),

            // Titre principal
            Text(
              'Rejoignez le Quiz!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E384D),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Entrez vos informations pour commencer',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Champ pour le nom
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Votre nom',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  hintText: 'Comment souhaitez-vous apparaître?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person, color: Color(0xFF5E76F2)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),

            // Champ pour le code de session
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: sessionCodeController,
                      decoration: InputDecoration(
                        labelText: 'Code de session',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        hintText: 'Saisissez le code à 6 chiffres',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.numbers, color: Color(0xFF5E76F2)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 20),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 16, letterSpacing: 2),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [Colors.amber[400]!, Colors.amber[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onScanQR,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            // Bouton rejoindre
            Container(
              height: 60,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5E76F2).withOpacity(0.4),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Color(0xFF5E76F2), Color(0xFF3955D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onJoin(sessionCodeController.text),
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Rejoindre la session',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}