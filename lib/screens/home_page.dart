import 'package:flutter/material.dart';
import 'package:mentimeeter/screens/admin/admin_home_screen.dart';
import 'package:mentimeeter/screens/participant/participants.dart';
import 'package:mentimeeter/screens/admin/login_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                                child: Text('About', style: TextStyle(color: Colors.white)),
                              ),

                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 60),
                      // Hero section
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create, Play, and Connect with Fun, Interactive Quizzes',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Join or create personalized quiz sessions that challenge your knowledge, foster learning, and bring people together in real-time!',
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
                              'assets/homepage.png',
                              height: 300,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),

            // Admin section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2463),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Create and manage engaging quiz sessions with ease',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A2463),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Take control of your quiz creation process. Craft fun, educational, or challenging quizzes, tailor each question, and manage real-time sessions with an intuitive admin interface. Once you have created a quiz, invite your participants to join using a unique session code.',
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
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E5CB3),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text('Get Started as Admin'),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Image.asset(
                'assets/quiz.png',
                height: 250,
              ),
            ),
          ],
        ),
      ),

      // Participant section with light blue background
      Container(
        width: double.infinity,
        color: Color(0xFFE6F0FF),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                'assets/imgadmin.png',
                height: 250,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participant Panel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A2463),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Join a quiz and challenge your knowledge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0A2463),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Jump into a quiz with a simple code. Test your skills and compete in real-time by answering questions and gaining points based on your speed and accuracy. Track your progress as you go, and see how you rank on the leaderboard.',
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
                    ),
                    child: Text('Join a Quiz Session'),
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