import 'package:flutter/material.dart';
import 'package:mentimeeter/models/question.dart';

class QuizScreen extends StatelessWidget {
  final String? participantName;
  final int score;
  final Question? currentQuestion;
  final bool questionActive;
  final bool hasAnswered;
  final int? selectedAnswerIndex;
  final int remainingTime;
  final bool? isAnswerCorrect;
  final bool quizEnded;
  final int rank;
  final Function(int) onSubmitAnswer;
  final VoidCallback onExit;

  const QuizScreen({
    Key? key,
    required this.participantName,
    required this.score,
    required this.currentQuestion,
    required this.questionActive,
    required this.hasAnswered,
    required this.selectedAnswerIndex,
    required this.remainingTime,
    required this.isAnswerCorrect,
    required this.quizEnded,
    required this.rank,
    required this.onSubmitAnswer,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quizEnded) {
      return _buildQuizEndedScreen();
    } else if (currentQuestion == null) {
      return _buildWaitingScreen();
    } else {
      return _buildQuestionScreen();
    }
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B48FF), Color(0xFF0097B2)],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: EdgeInsets.all(24),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_top,
                      size: 70,
                      color: Color(0xFF6B48FF),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'En attente du démarrage du quiz...',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      participantName ?? 'Participant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B48FF),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.score, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Score: $score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B48FF)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen() {
    if (currentQuestion == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B48FF)),
        ),
      );
    }

    String questionText = currentQuestion!.questionText;
    List<String> options = currentQuestion!.options;
    bool showAnswerStatus = hasAnswered && !questionActive;

    final List<Color> buttonBaseColors = [
      Color(0xFFFFFFFF), // Red
      Color(0xFFFFFFFF), // Blue
      Color(0xFFFFFFFF), // Yellow
      Color(0xFFFFFFFF), // Green
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B48FF), Color(0xFF0097B2)],
              stops: [0.0, 1.0],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with score and timer
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars, color: Colors.amber),
                          SizedBox(width: 10),
                          Text(
                            '$score',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      if (questionActive)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: remainingTime > 10 ? Colors.green.shade500 : Colors.red.shade500,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                '$remainingTime',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Question card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Color(0xFF6B48FF),
                        size: 40,
                      ),
                      SizedBox(height: 16),
                      Text(
                        questionText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Answer options
                Expanded(
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedAnswerIndex == index;
                      bool isCorrect = currentQuestion!.correctAnswerIndex == index;

                      Color baseColor = buttonBaseColors[index % 4];
                      Color backgroundColor;
                      IconData? optionIcon;

                      if (showAnswerStatus) {
                        if (isCorrect) {
                          backgroundColor = Colors.green.shade500;
                          optionIcon = Icons.check_circle;
                        } else if (isSelected) {
                          backgroundColor = Colors.red.shade500;
                          optionIcon = Icons.cancel;
                        } else {
                          backgroundColor = baseColor.withOpacity(0.7);
                        }
                      } else {
                        backgroundColor = isSelected
                            ? baseColor
                            : baseColor.withOpacity(0.7);
                      }

                      List<BoxShadow> boxShadows = isSelected
                          ? [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.6),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                          spreadRadius: 2,
                        )
                      ]
                          : [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ];

                      return GestureDetector(
                        onTap: () {
                          if (questionActive && !hasAnswered) {
                            onSubmitAnswer(index);
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: boxShadows,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: isSelected ? 3.0 : 0.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    options[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              if (optionIcon != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      optionIcon,
                                      color: isCorrect ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 16),

                // Status indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: hasAnswered
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        questionActive
                            ? Icons.send
                            : (isAnswerCorrect == true
                            ? Icons.check_circle
                            : Icons.cancel),
                        color: questionActive
                            ? Colors.blue
                            : (isAnswerCorrect == true
                            ? Colors.green
                            : Colors.red),
                      ),
                      SizedBox(width: 10),
                      Text(
                        questionActive
                            ? 'Réponse envoyée!'
                            : (isAnswerCorrect == true
                            ? 'Correct!'
                            : 'Incorrect!'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: questionActive
                              ? Colors.blue
                              : (isAnswerCorrect == true
                              ? Colors.green
                              : Colors.red),
                        ),
                      ),
                    ],
                  )
                      : Text(
                    questionActive
                        ? 'Choisissez une réponse'
                        : 'En attente de la prochaine question...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizEndedScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B48FF), Color(0xFF0097B2)],
          ),
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy icon
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 30),

                // Quiz ended text
                Text(
                  'Quiz terminé!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Score card
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 30),
                            SizedBox(width: 10),
                            Text(
                              'Score final',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B48FF),
                          ),
                        ),
                        Divider(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.leaderboard, color: Colors.indigo, size: 30),
                            SizedBox(width: 10),
                            Text(
                              'Votre rang',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: rank <= 3 ? Colors.amber.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: rank <= 3 ? Colors.amber : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: rank <= 3 ? Colors.amber.shade800 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Exit button
                ElevatedButton(
                  onPressed: onExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF6B48FF),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black38,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(width: 10),
                      Text(
                        'Quitter',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}