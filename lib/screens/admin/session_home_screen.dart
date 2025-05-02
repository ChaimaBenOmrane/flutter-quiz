import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:mentimeeter/models/question.dart';
import 'package:mentimeeter/models/quiz.dart';
import 'package:mentimeeter/screens/admin/waiting_room_screen.dart';
import 'package:mentimeeter/screens/admin/quiz_presenter_screen.dart';

class SessionScreen extends StatefulWidget {
  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? selectedQuizId;
  String? selectedQuizTitle;
  String sessionCode = '';
  bool isSessionStarted = false;
  bool isQuizLaunched = false;
  List<Map<String, dynamic>> quizzes = [];
  List<Map<String, dynamic>> participants = [];
  List<Question> questions = [];
  int currentQuestionIndex = -1;
  Timer? questionTimer;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  @override
  void dispose() {
    questionTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuizzes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('quizzes').get();
      print('Fetched ${snapshot.docs.length} quizzes');

      List<Map<String, dynamic>> loadedQuizzes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data.containsKey('title') ? data['title'] : 'Quiz sans titre',
        };
      }).toList();

      setState(() {
        quizzes = loadedQuizzes;
      });
    } catch (e) {
      print('Error fetching quizzes: $e');
    }
  }

  Future<void> _loadQuizQuestions() async {
    if (selectedQuizId == null) {
      print('No quiz selected');
      return;
    }

    try {
      print('Loading questions for quiz ID: $selectedQuizId');
      DocumentSnapshot quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(selectedQuizId)
          .get();

      if (quizDoc.exists) {
        Map<String, dynamic> data = quizDoc.data() as Map<String, dynamic>;
        print('Quiz data: $data');

        if (data.containsKey('questions') && data['questions'] is List) {
          List<dynamic> questionsData = data['questions'];
          print('Found ${questionsData.length} questions');

          List<Question> loadedQuestions = [];

          for (var questionData in questionsData) {
            try {
              Map<String, dynamic> adaptedQuestion = {
                'questionText': questionData['questionText'],
                'options': questionData['answers'].map((answer) => answer['text']).toList(),
                'correctAnswerIndex': _findCorrectAnswerIndex(questionData['answers']),
                'timeLimit': questionData['duration'],
              };

              Question question = Question.fromMap(adaptedQuestion);
              loadedQuestions.add(question);
            } catch (e) {
              print('Error processing question: $e');
            }
          }

          print('Successfully converted ${loadedQuestions.length} questions');

          setState(() {
            questions = loadedQuestions;
          });
        } else {
          print('Error: Quiz document does not contain a valid questions array');
          setState(() {
            questions = [];
          });
        }
      } else {
        print('Quiz document does not exist');
        setState(() {
          questions = [];
        });
      }
    } catch (e) {
      print('Error loading quiz questions: $e');
      setState(() {
        questions = [];
      });
    }
  }

  int _findCorrectAnswerIndex(List<dynamic> answers) {
    for (int i = 0; i < answers.length; i++) {
      if (answers[i]['isCorrect'] == true) {
        return i;
      }
    }
    return 0; // Default to first option if none are correct
  }

  String _generateSessionCode() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  Future<void> _startWaitingSession() async {
    if (selectedQuizId != null) {
      sessionCode = _generateSessionCode();

      await _loadQuizQuestions();

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Impossible de charger les questions du quiz'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('sessions').doc(sessionCode).set({
        'quizId': selectedQuizId,
        'quizTitle': selectedQuizTitle,
        'createdAt': Timestamp.now(),
        'isStarted': false,
        'isEnded': false,
        'sessionCode': sessionCode,
        'currentQuestionIndex': -1,
        'questionActive': false,
        'questionsCount': questions.length,
      });

      _listenForParticipants();
      setState(() {
        isSessionStarted = true;
        currentQuestionIndex = -1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un quiz'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  void _listenForParticipants() {
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionCode)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        participants = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    });
  }

  Future<void> _launchQuiz() async {
    if (questions.isEmpty) {
      await _loadQuizQuestions();

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Aucune question trouvée pour ce quiz'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    await FirebaseFirestore.instance.collection('sessions').doc(sessionCode).update({
      'isStarted': true,
    });

    setState(() {
      isQuizLaunched = true;
    });
  }

  void _onSessionEnd() {
    setState(() {
      isSessionStarted = false;
      isQuizLaunched = false;
      sessionCode = '';
      participants = [];
      currentQuestionIndex = -1;
      questions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Quiz selection screen
    if (!isSessionStarted) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A2463), Color(0xFF1E5CB3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Navigation bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Icon(Icons.play_circle_filled, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'QuizTime',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Section title
                        Text(
                          'Créer une session',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sélectionnez un quiz pour commencer une nouvelle session',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),

              // Quiz selection section
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.quiz, color: Color(0xFF1E5CB3), size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'Sélectionner un quiz',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0A2463),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Choisissez parmi vos quizzes existants',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 20),
                            quizzes.isEmpty
                                ? Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E5CB3)),
                                  ),
                                  SizedBox(height: 16),
                                  Text('Chargement des quizzes...'),
                                ],
                              ),
                            )
                                : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  border: InputBorder.none,
                                ),
                                hint: Text('Choisissez un quiz'),
                                value: selectedQuizId,
                                onChanged: (newQuizId) {
                                  if (newQuizId != null) {
                                    var quiz = quizzes.firstWhere((q) => q['id'] == newQuizId);
                                    setState(() {
                                      selectedQuizId = newQuizId;
                                      selectedQuizTitle = quiz['title'];
                                      questions = [];
                                    });
                                  }
                                },
                                items: quizzes.map((quiz) {
                                  return DropdownMenuItem<String>(
                                    value: quiz['id'],
                                    child: Text(quiz['title']),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 30),
                            Center(
                              child: ElevatedButton(
                                onPressed: selectedQuizId != null ? _startWaitingSession : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1E5CB3),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade400,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow),
                                    SizedBox(width: 8),
                                    Text(
                                      'Créer la session',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Quiz information section
                    if (selectedQuizId != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Color(0xFF1E5CB3), size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    'Informations sur le quiz',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0A2463),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFFE6F0FF),
                                  child: Icon(Icons.title, color: Color(0xFF1E5CB3)),
                                ),
                                title: Text('Titre'),
                                subtitle: Text(selectedQuizTitle ?? 'Quiz sans titre'),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFFE6F0FF),
                                  child: Icon(Icons.lock_outline, color: Color(0xFF1E5CB3)),
                                ),
                                title: Text('Accès'),
                                subtitle: Text('Code de session généré automatiquement'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Footer
              Container(
                width: double.infinity,
                color: Color(0xFF0A2463),
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '© 2025 QuizTime. Created by Chaima Mariem.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Waiting room screen or quiz presenter screen
    else if (!isQuizLaunched) {
      return WaitingRoomScreen(
        sessionCode: sessionCode,
        selectedQuizTitle: selectedQuizTitle ?? '',
        questionsCount: questions.length,
        participants: participants,
        onLaunchQuiz: _launchQuiz,
      );
    }
    // Quiz presenter screen
    else {
      return QuizPresenterScreen(
        sessionCode: sessionCode,
        questions: questions,
        participants: participants,
        onSessionEnd: _onSessionEnd,
      );
    }
  }
}