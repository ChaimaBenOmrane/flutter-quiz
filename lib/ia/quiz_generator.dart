import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_io/io.dart';

import 'package:mentimeeter/screens/admin/quiz_list_screen.dart';

class QuizGeneratorPage extends StatefulWidget {
  const QuizGeneratorPage({Key? key}) : super(key: key);

  @override
  State<QuizGeneratorPage> createState() => _QuizGeneratorPageState();
}

class _QuizGeneratorPageState extends State<QuizGeneratorPage> {
  final TextEditingController _quizTitleController = TextEditingController();
  final TextEditingController _numQuestionsController = TextEditingController(text: '5');
  final TextEditingController _timePerQuestionController = TextEditingController(text: '30');

  // URL du serveur FastAPI - MODIFIÉ POUR UTILISER PLUSIEURS OPTIONS SELON LA PLATEFORME
  String get _apiUrl {
    // Pour l'émulateur Android (utiliser l'API de la machine hôte)
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/generate-quiz';
    }
    // Pour les tests sur Web ou iOS
    else if (_isWeb || Platform.isIOS) {
      return 'http://localhost:8000/generate-quiz';
    }
    // Fallback
    else {
      return 'http://localhost:8000/generate-quiz';
    }
  }

  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  String? _generatedQuizId;
  bool get _isWeb => identical(0, 0.0);

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true, // Très important pour le web, charge les données en mémoire
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
      );
    }
  }

  Future<void> _generateQuiz() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner un fichier.')),
      );
      return;
    }

    if (_quizTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un titre pour le quiz.')),
      );
      return;
    }

    int numQuestions = int.tryParse(_numQuestionsController.text) ?? 5;
    int timePerQuestion = int.tryParse(_timePerQuestionController.text) ?? 30;

    if (numQuestions <= 0 || numQuestions > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nombre de questions doit être entre 1 et 20.')),
      );
      return;
    }

    if (timePerQuestion < 10 || timePerQuestion > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le temps par question doit être entre 10 et 120 secondes.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Génération du quiz en cours...';
      _isSuccess = false;
      _generatedQuizId = null;
    });

    try {
      // Afficher l'URL utilisée pour le débogage
      print('Tentative de connexion à: $_apiUrl');

      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      // Ajouter les paramètres de configuration
      request.fields['title'] = _quizTitleController.text;
      request.fields['num_questions'] = numQuestions.toString();
      request.fields['time_per_question'] = timePerQuestion.toString();

      // Gestion du fichier selon la plateforme
      if (_selectedFile != null) {
        if (_isWeb) {
          // Pour le web, on utilise les bytes du fichier
          if (_selectedFile!.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'file',
              _selectedFile!.bytes!,
              filename: _selectedFile!.name,
            ));
          } else {
            throw Exception('Impossible de charger le contenu du fichier');
          }
        } else {
          // Pour mobile, on utilise le chemin du fichier
          if (_selectedFile!.path != null) {
            request.files.add(await http.MultipartFile.fromPath(
              'file',
              _selectedFile!.path!,
              filename: _selectedFile!.name,
            ));
          } else {
            throw Exception('Chemin du fichier non disponible');
          }
        }
      }

      // Définir un timeout pour la requête
      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La connexion au serveur a expiré. Vérifiez que le serveur est bien lancé et accessible.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        _generatedQuizId = responseData['quiz_id'];
        setState(() {
          _isLoading = false;
          _statusMessage = 'Quiz généré avec succès!';
          _isSuccess = true;
        });
      } else {
        // Si la réponse n'est pas 200, récupérer le message d'erreur
        var errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          errorData = {'detail': 'Erreur de communication avec le serveur'};
        }
        throw Exception('Erreur serveur: ${errorData['detail'] ?? response.statusCode}');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erreur: $e';
        _isSuccess = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération du quiz: $e')),
      );
    }
  }

  @override
  void dispose() {
    _quizTitleController.dispose();
    _numQuestionsController.dispose();
    _timePerQuestionController.dispose();
    super.dispose();
  }

  Widget _buildInfoCard(String title, {required Widget child}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
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
              color: Color(0xFF1E5CB3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
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
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Générer un Quiz avec IA'),
        backgroundColor: Color(0xFF0A2463),
        foregroundColor: Colors.white,
        elevation: 0,
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
                  _buildInfoCard(
                    'Paramètres du Quiz',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        SizedBox(height: 16),
                        TextField(
                          controller: _numQuestionsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nombre de questions',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: Icon(Icons.format_list_numbered),
                            helperText: 'Entre 1 et 20 questions',
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _timePerQuestionController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Temps par question (secondes)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: Icon(Icons.timer),
                            helperText: 'Entre 10 et 120 secondes',
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildInfoCard(
                    'Fichier à Analyser',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sélectionnez un document (PDF, DOCX, TXT) à partir duquel générer le quiz :',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                                    color: _selectedFile != null ? Colors.green : Colors.grey,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedFile != null
                                          ? 'Fichier sélectionné: ${_selectedFile!.name}'
                                          : 'Aucun fichier sélectionné',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedFile != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: Icon(Icons.file_upload),
                                  label: Text('Sélectionner un fichier'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1E5CB3),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


                  if (_isLoading || _isSuccess)
                    _buildInfoCard(
                      'Statut',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            CircularProgressIndicator(
                              color: Color(0xFF1E5CB3),
                            ),
                          SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isSuccess ? Colors.green : Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_isSuccess && _generatedQuizId != null)
                            Column(
                              children: [
                                SizedBox(height: 16),
                                Text(
                                  'ID du Quiz: $_generatedQuizId',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => QuizListPage()),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Navigation vers le quiz: $_generatedQuizId')),
                                    );
                                  },
                                  icon: Icon(Icons.launch),
                                  label: Text('Voir le Quiz'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1E5CB3),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                  SizedBox(height: 32),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateQuiz,
                      icon: Icon(Icons.auto_awesome),
                      label: Text('Générer le Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0A2463),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        disabledBackgroundColor: Colors.grey,
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