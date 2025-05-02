import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditQuizPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const EditQuizPage({required this.quizId, required this.quizData, Key? key}) : super(key: key);

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  late TextEditingController _titleController;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quizData['title']);
    _questions = List<Map<String, dynamic>>.from(widget.quizData['questions'] ?? []);
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).update({
        'title': _titleController.text,
        'questions': _questions,
        'lastModified': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz modifié avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur modification quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de modification: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add({
        'questionText': 'Nouvelle question',
        'answers': [
          {'text': 'Réponse 1', 'isCorrect': true},
          {'text': 'Réponse 2', 'isCorrect': false},
          {'text': 'Réponse 3', 'isCorrect': false},
          {'text': 'Réponse 4', 'isCorrect': false},
        ],
      });
    });

    // Défiler jusqu'à la nouvelle question
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la question?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    final TextEditingController questionTextController = TextEditingController(text: question['questionText']);
    final List<TextEditingController> answerControllers = List.generate(
      question['answers'].length,
          (i) => TextEditingController(text: question['answers'][i]['text']),
    );

    int correctAnswerIndex = (question['answers'] as List).indexWhere((answer) => answer['isCorrect'] == true);
    if (correctAnswerIndex == -1) correctAnswerIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Modifier la Question'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: questionTextController,
                          decoration: const InputDecoration(
                            labelText: 'Texte de la question',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Réponses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(question['answers'].length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: i,
                                  groupValue: correctAnswerIndex,
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      correctAnswerIndex = value!;
                                    });
                                  },
                                  activeColor: Colors.green,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: answerControllers[i],
                                    decoration: InputDecoration(
                                      labelText: 'Réponse ${i + 1}',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5F5),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: question['answers'].length > 2
                                            ? () {
                                          setStateDialog(() {
                                            question['answers'].removeAt(i);
                                            answerControllers.removeAt(i);
                                            if (correctAnswerIndex == i) {
                                              correctAnswerIndex = 0;
                                            } else if (correctAnswerIndex > i) {
                                              correctAnswerIndex--;
                                            }
                                          });
                                        }
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        if (question['answers'].length < 6)
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une réponse'),
                            onPressed: () {
                              setStateDialog(() {
                                question['answers'].add({'text': '', 'isCorrect': false});
                                answerControllers.add(TextEditingController(text: ''));
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        question['questionText'] = questionTextController.text;

                        for (int i = 0; i < question['answers'].length; i++) {
                          question['answers'][i]['text'] = answerControllers[i].text;
                          question['answers'][i]['isCorrect'] = (i == correctAnswerIndex);
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  final ScrollController _scrollController = ScrollController();

  Widget _buildQuestionItem(int index) {
    final question = _questions[index];

    // Trouver la réponse correcte
    int correctIndex = (question['answers'] as List).indexWhere((answer) => answer['isCorrect'] == true);
    String correctAnswer = correctIndex >= 0 ? question['answers'][correctIndex]['text'] : "Aucune";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _editQuestion(index),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.indigo.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question['questionText'] ?? 'Question sans texte',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        onPressed: () => _editQuestion(index),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteQuestion(index),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(question['answers'] as List).length} réponses • Réponse correcte: "$correctAnswer"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (question['answers'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: entry.value['isCorrect']
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: entry.value['isCorrect']
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              entry.value['text'],
                              style: TextStyle(
                                color: entry.value['isCorrect']
                                    ? Colors.green.shade700
                                    : Colors.grey.shade800,
                              ),
                            ),
                          );
                        })
                            .toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifier Quiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Quitter sans sauvegarder?'),
                content: const Text('Toutes les modifications non sauvegardées seront perdues.'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Fermer le dialogue
                      Navigator.pop(context); // Quitter la page d'édition
                    },
                    child: const Text('Quitter', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Titre du Quiz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Saisissez le titre du quiz',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.indigo),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions (${_questions.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addNewQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _questions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.question_mark,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune question',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addNewQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _questions.length,
                  itemBuilder: (context, index) => _buildQuestionItem(index),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveChanges,
          icon: _isLoading
              ? Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(2.0),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les modifications'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            disabledBackgroundColor: Colors.indigo.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}