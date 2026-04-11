import 'package:flutter/material.dart';
import 'login.dart'; // Ensure these filenames match exactly
import 'signup.dart';
import 'home.dart';


void main() {
  runApp(const TicketyApp());
}

class TicketyApp extends StatelessWidget {
  const TicketyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tickety Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // This tells the app to start on the Login Page
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => Homepage(),
      },
    );
  }
}