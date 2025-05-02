import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentimeeter/ia/quiz_generator.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({Key? key}) : super(key: key);

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '30');

  List<TextEditingController> _answerControllers = [];
  int _correctAnswerIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  int _numberOfAnswers = 2;

  final List<Color> _answerColors = [
    Color(0xFFFBDDDD), // rose clair
    Color(0xFFFDE1AC), // jaune clair
    Color(0xFFBAE5F5), // bleu clair
    Color(0xFFC8C1E2), // violet clair
  ];

  @override
  void initState() {
    super.initState();
    _initAnswers();
  }

  void _initAnswers() {
    _answerControllers = List.generate(4, (index) => TextEditingController());
  }

  void _clearQuestionFields() {
    _questionController.clear();
    _durationController.text = '30';
    _initAnswers();
    _correctAnswerIndex = 0;
    _numberOfAnswers = 2;
  }

  void _addQuestion() {
    if (_questionController.text.isEmpty ||
        _answerControllers.sublist(0, _numberOfAnswers).any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir la question et toutes les réponses.')),
      );
      return;
    }

    final question = {
      'questionText': _questionController.text,
      'duration': int.tryParse(_durationController.text) ?? 30,
      'answers': List.generate(_numberOfAnswers, (index) {
        return {
          'text': _answerControllers[index].text,
          'isCorrect': index == _correctAnswerIndex,
        };
      }),
    };

    setState(() {
      _questions.add(question);
      _clearQuestionFields();
    });
  }

  Future<void> _saveQuiz() async {
    if (_quizTitleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un titre de quiz et au moins une question.')),
      );
      return;
    }

    final quizData = {
      'title': _quizTitleController.text,
      'questions': _questions,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('quizzes').add(quizData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz enregistré avec succès !')),
      );

      setState(() {
        _quizTitleController.clear();
        _questions.clear();
        _clearQuestionFields();
      });
    } catch (e) {
      print('Erreur enregistrement quiz : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement du quiz.')),
      );
    }
  }

  @override
  void dispose() {
    _quizTitleController.dispose();
    _questionController.dispose();
    _durationController.dispose();
    _answerControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Widget buildAnswerCard(int index) {
    bool isSelected = _correctAnswerIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _correctAnswerIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _answerColors[index],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.green : Colors.grey,
              size: 28,
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _answerControllers[index],
                decoration: InputDecoration(
                  hintText: 'Réponse ${index + 1}',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: color ?? Color(0xFF0A2463),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  title == 'Informations du Quiz' ? Icons.quiz :
                  title == 'Créer une Question' ? Icons.help_outline :
                  title == 'Questions Ajoutées' ? Icons.list_alt : Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un Quiz'),
        backgroundColor: Color(0xFF0A2463),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuizGeneratorPage()),
              );
            },
            icon: Icon(
              Icons.auto_awesome,
              color: Colors.white,
            ),
            label: Text(
              "Générer avec IA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE6F0FF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Informations du Quiz',
                    color: Color(0xFF1E5CB3),
                    children: [
                      TextField(
                        controller: _quizTitleController,
                        decoration: InputDecoration(
                          labelText: 'Titre du Quiz',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                    ],
                  ),

                  _buildSectionCard(
                    title: 'Créer une Question',
                    color: Color(0xFF1E5CB3),
                    children: [
                      TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Question',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Icon(Icons.help_outline),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Durée (secondes)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                      SizedBox(height: 24),

                      Text(
                        'Sélectionnez la bonne réponse :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),

                      ...List.generate(_numberOfAnswers, (index) => buildAnswerCard(index)),

                      if (_numberOfAnswers < 4)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (_numberOfAnswers < 4) _numberOfAnswers++;
                              });
                            },
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Ajouter une réponse'),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF1E5CB3),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                      SizedBox(height: 24),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: Icon(Icons.add),
                          label: Text('Ajouter la Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E5CB3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_questions.isNotEmpty)
                    _buildSectionCard(
                      title: 'Questions Ajoutées',
                      color: Color(0xFF0A2463),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE6F0FF),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Color(0xFF0A2463),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            question['questionText'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${question['duration']} sec',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: (question['answers'] as List)
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        Color bgColor = _answerColors[entry.key % _answerColors.length];
                                        bool isCorrect = entry.value['isCorrect'];
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 8),
                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: bgColor.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isCorrect ? Colors.green : Colors.transparent,
                                              width: isCorrect ? 2 : 0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (isCorrect)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                              if (!isCorrect)
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              SizedBox(width: 12),
                                              Text(
                                                entry.value['text'],
                                                style: TextStyle(
                                                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveQuiz,
                      icon: Icon(Icons.save),
                      label: Text('Enregistrer le Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0A2463),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}