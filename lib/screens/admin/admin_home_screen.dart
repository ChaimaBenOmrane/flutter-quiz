import 'package:flutter/material.dart';
import 'package:mentimeeter/screens/admin/quiz_list_screen.dart';
import 'create_quiz.dart';
import 'session_home_screen.dart';
import 'package:mentimeeter/models/quiz.dart';
import 'package:mentimeeter/screens/participant/participants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentimeeter/screens/admin/login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      // Redirection vers la page d'accueil après déconnexion
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false, // Supprime toutes les routes précédentes de la pile
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Récupérer le nom d'utilisateur actuel
    String? username = _auth.currentUser?.displayName ?? 'Admin';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with gradient background
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
                              TextButton(
                                onPressed: () {},
                                child: Text('Dashboard', style: TextStyle(color: Colors.white)),
                              ),
                              SizedBox(width: 8),
                              TextButton(
                                onPressed: () {},
                                child: Text('Profile', style: TextStyle(color: Colors.white)),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _logout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 16),
                                    SizedBox(width: 4),
                                    Text('Logout'),
                                    ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      // Hero section
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Dashboard',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Create and manage your interactive quiz experiences with powerful and intuitive tools.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Image.asset(
                              'homeadmin.png',
                              height: 250,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Quiz Creation Section - Text left, Image right
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text on the left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz Creation',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Design engaging quizzes with ease',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Build your perfect quiz with ease. Add multiple-choice questions, set time limits for each one, and adjust difficulty. Whether you\'re creating a quiz for fun or for learning, it\'s all about making the experience enjoyable for both creators and participants.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateQuizPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E5CB3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Create Quiz'),
                        ),
                      ],
                    ),
                  ),
                  // Image on the right
                  SizedBox(width: 20),
                  Expanded(
                    child: Image.asset(
                      'quizcreate.png', // You'll need to add this image
                      height: 250,
                    ),
                  ),
                ],
              ),
            ),

            // Real-Time Session Management - Image left, Text right
            Container(
              width: double.infinity,
              color: Color(0xFFE6F0FF),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image on the left
                  Expanded(
                    child: Image.asset(
                      'session_management.png', // You'll need to add this image
                      height: 250,
                    ),
                  ),
                  // Text on the right
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-Time Session Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Guide participants through interactive quiz experiences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Create and manage live quiz sessions effortlessly. As an administrator, guide participants through each question and display results as they happen. Stay connected with your audience and adjust the flow to keep the excitement high.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SessionScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E5CB3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Manage Sessions'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of Quizzes - Text left, Image right
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text on the left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'List of Quizzes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Manage your collection of interactive quizzes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Easily access all your existing quizzes in one place. Review their content, update questions, or launch a new session. Whether you\'re preparing for a class, an event, or a fun game night, your quizzes are always ready to go.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QuizListPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E5CB3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Browse Quizzes'),
                        ),
                      ],
                    ),
                  ),
                  // Image on the right
                  SizedBox(width: 20),
                  Expanded(
                    child: Image.asset(
                      'listequiz.png', // You'll need to add this image
                      height: 250,
                    ),
                  ),
                ],
              ),
            ),

            // Participant Experience - Image left, Text right
            Container(
              width: double.infinity,
              color: Color(0xFFE6F0FF),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image on the left
                  Expanded(
                    child: Image.asset(
                      'participants.png', // You'll need to add this image
                      height: 250,
                    ),
                  ),
                  // Text on the right
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participant Experience',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Understand your quiz from the participant\'s perspective',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Stay connected with live sessions for everyone. Experience the quiz from a participant\'s perspective to better understand your audience\'s journey and optimize your future quizzes.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ParticipantScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E5CB3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('View Participant Mode'),
                        ),
                      ],
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
                  style: TextStyle(
                    color: Colors.white70,
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