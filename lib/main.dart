import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mentimeeter/screens/home_page.dart';
import 'package:mentimeeter/screens/participant/participants.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mentimeeter/ia/quiz_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MentimeeterApp());
}

class MentimeeterApp extends StatelessWidget {
  const MentimeeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentimeeter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),

    );
  }
}
