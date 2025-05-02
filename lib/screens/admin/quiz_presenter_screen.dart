import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:mentimeeter/models/question.dart';

class QuizPresenterScreen extends StatefulWidget {
  final String sessionCode;
  final List<Question> questions;
  final List<Map<String, dynamic>> participants;
  final Function onSessionEnd;

  const QuizPresenterScreen({
    Key? key,
    required this.sessionCode,
    required this.questions,
    required this.participants,
    required this.onSessionEnd,
  }) : super(key: key);

  @override
  _QuizPresenterScreenState createState() => _QuizPresenterScreenState();
}

class _QuizPresenterScreenState extends State<QuizPresenterScreen> {
  int currentQuestionIndex = -1;
  bool isQuestionActive = false;
  Timer? questionTimer;
  int remainingTime = 0;

  Map<String, dynamic> currentQuestionStats = {
    'totalAnswers': 0,
    'correctAnswers': 0,
    'optionCounts': <int, int>{},
  };

  @override
  void initState() {
    super.initState();
    // Start quiz with first question
    _moveToNextQuestion();
  }

  @override
  void dispose() {
    questionTimer?.cancel();
    super.dispose();
  }

  Future<void> _moveToNextQuestion() async {
    // Reset question stats
    currentQuestionStats = {
      'totalAnswers': 0,
      'correctAnswers': 0,
      'optionCounts': <int, int>{},
    };

    // Stop previous timer if running
    questionTimer?.cancel();

    int nextIndex = currentQuestionIndex + 1;
    if (nextIndex >= widget.questions.length) {
      _endSession();
      return;
    }

    setState(() {
      currentQuestionIndex = nextIndex;
      isQuestionActive = true;
      remainingTime = widget.questions[nextIndex].timeLimit;
    });

    // Print debug information
    print('Moving to question ${nextIndex + 1}/${widget.questions.length}: ${widget.questions[nextIndex].questionText}');

    // Update in Firestore
    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionCode).update({
      'currentQuestionIndex': nextIndex,
      'questionActive': true,
      'questionStartTime': FieldValue.serverTimestamp(),
      'questionEndTime': Timestamp.fromDate(
        DateTime.now().add(Duration(seconds: widget.questions[nextIndex].timeLimit)),
      ),
    });

    // Listen for answers to this question
    _listenForQuestionAnswers(nextIndex);

    // Start timer
    questionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          _endQuestion();
          timer.cancel();
        }
      });
    });
  }

  void _listenForQuestionAnswers(int questionIndex) {
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionCode)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .snapshots()
        .listen((snapshot) {
      int total = snapshot.docs.length;
      int correct = snapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data();
        return data['isCorrect'] == true;
      }).length;

      Map<int, int> optionCounts = {};
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        int answerIndex = data['answerIndex'] ?? 0;
        optionCounts[answerIndex] = (optionCounts[answerIndex] ?? 0) + 1;
      }

      setState(() {
        currentQuestionStats = {
          'totalAnswers': total,
          'correctAnswers': correct,
          'optionCounts': optionCounts,
        };
      });
    });
  }

  Future<void> _endQuestion() async {
    if (!isQuestionActive) return;

    setState(() {
      isQuestionActive = false;
    });

    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionCode).update({
      'questionActive': false,
    });
  }

  void _endSession() async {
    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionCode).update({
      'isEnded': true,
    });

    _showLeaderboard();
  }

  void _showLeaderboard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        List<Map<String, dynamic>> sortedParticipants = List.from(widget.participants);
        sortedParticipants.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Classement final',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2463),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: sortedParticipants.isEmpty
                      ? Center(child: Text('Aucun participant', style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedParticipants.length,
                    itemBuilder: (context, index) {
                      var participant = sortedParticipants[index];

                      Color medalColor;
                      Color backgroundColor;
                      IconData? medalIcon;

                      if (index == 0) {
                        medalColor = Colors.amber;
                        backgroundColor = Colors.amber.withOpacity(0.1);
                        medalIcon = Icons.emoji_events;
                      } else if (index == 1) {
                        medalColor = Colors.grey[400]!;
                        backgroundColor = Colors.grey[100]!;
                        medalIcon = Icons.emoji_events;
                      } else if (index == 2) {
                        medalColor = Colors.brown[300]!;
                        backgroundColor = Colors.brown[50]!;
                        medalIcon = Icons.emoji_events;
                      } else {
                        medalColor = Colors.blue[300]!;
                        backgroundColor = Colors.white;
                        medalIcon = null;
                      }

                      return Card(
                        elevation: index < 3 ? 3 : 1,
                        color: backgroundColor,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: medalColor,
                            foregroundColor: Colors.white,
                            child: medalIcon != null
                                ? Icon(medalIcon)
                                : Text('${index + 1}'),
                          ),
                          title: Text(
                            participant['name'],
                            style: TextStyle(
                              fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E5CB3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${participant['score'] ?? 0} pts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Fermer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF1E5CB3),
                        side: BorderSide(color: Color(0xFF1E5CB3)),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSessionEnd();
                      },
                      child: Text('Nouveau Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E5CB3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionStatistics() {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= widget.questions.length) {
      return SizedBox.shrink();
    }

    Question question = widget.questions[currentQuestionIndex];
    int totalAnswers = currentQuestionStats['totalAnswers'] ?? 0;
    int correctAnswers = currentQuestionStats['correctAnswers'] ?? 0;
    Map<dynamic, dynamic> optionCounts = currentQuestionStats['optionCounts'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Color(0xFF1E5CB3), size: 24),
                SizedBox(width: 12),
                Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2463),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Color(0xFF1E5CB3)),
                      SizedBox(width: 8),
                      Text(
                        'Réponses reçues:',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    '$totalAnswers / ${widget.participants.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E5CB3),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            if (!isQuestionActive) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Réponses correctes:',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Text(
                      '$correctAnswers (${totalAnswers > 0 ? (correctAnswers * 100 ~/ totalAnswers) : 0}%)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Distribution des réponses:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2463),
                ),
              ),
              SizedBox(height: 12),
              ...question.options.asMap().entries.map((entry) {
                int index = entry.key;
                String option = entry.value;
                int count = optionCounts[index] ?? 0;
                bool isCorrect = index == question.correctAnswerIndex;
                double percentage = totalAnswers > 0 ? count / totalAnswers : 0;

                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCorrect) Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: isCorrect ? 4 : 0),
                          Text(
                            '${String.fromCharCode(65 + index)}. $option',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.black87,
                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.7 * percentage,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green : Color(0xFF1E5CB3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            height: 24,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${count} (${(percentage * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= widget.questions.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune question disponible', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    Question question = widget.questions[currentQuestionIndex];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Color(0xFF1E5CB3), size: 24),
                SizedBox(width: 12),
                Text(
                  'Question',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2463),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question.questionText,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Options:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2463),
              ),
            ),
            SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value.toString();
              bool isCorrect = index == question.correctAnswerIndex;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: !isQuestionActive && isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isQuestionActive && isCorrect ? Colors.green : Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: !isQuestionActive && isCorrect
                              ? Colors.green
                              : Color(0xFF1E5CB3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: !isQuestionActive && isCorrect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (!isQuestionActive && isCorrect)
                        Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          Row(
                            children: [
                              Text(
                                'Code: ${widget.sessionCode}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${currentQuestionIndex + 1}/${widget.questions.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Participants: ${widget.participants.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          if (isQuestionActive)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: remainingTime < 5 ? Colors.red : Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    '$remainingTime s',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentQuestion(),
                  SizedBox(height: 20),
                  _buildQuestionStatistics(),
                  SizedBox(height: 24),

                  // Control buttons
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Color(0xFF1E5CB3), size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Contrôles',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A2463),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isQuestionActive)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.stop_circle),
                                    label: Text('Terminer la question'),
                                    onPressed: _endQuestion,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              if (!isQuestionActive) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.navigate_next),
                                    label: Text('Question suivante'),
                                    onPressed: currentQuestionIndex < widget.questions.length - 1
                                        ? _moveToNextQuestion
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF1E5CB3),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBackgroundColor: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.stop),
                                    label: Text('Terminer le quiz'),
                                    onPressed: _endSession,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
}