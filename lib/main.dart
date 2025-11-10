import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drepto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00B2A9), // Matched from logo
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF00B2A9), // Matched from logo
          secondary: const Color(0xFF4A148C), // Deep Purple
          tertiary: const Color(0xFF00B2A9), // Complementary color for accents
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B2A9), // Matched from logo
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
