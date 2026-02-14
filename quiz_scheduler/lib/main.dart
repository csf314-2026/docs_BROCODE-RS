import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const QuizSchedulerApp());
}

class QuizSchedulerApp extends StatelessWidget {
  const QuizSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Scheduler',

      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),

      home: const HomePage(), // Bypass login for now
    );
  }
}
