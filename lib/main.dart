import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_setup_page.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show splash screen while checking authentication state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = authSnapshot.data;

        // If user is not logged in, go to LoginPage
        if (user == null) {
          return const LoginPage();
        }

        // If user is logged in, check their profile status
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            // Show splash screen while loading user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // Handle errors in fetching user data
            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Error loading profile data."),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Try again
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                          );
                        },
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // If profile document doesn't exist, go to profile setup
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const ProfileSetupPage();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            final isComplete = data != null && data['isProfileComplete'] == true;

            // If profile is complete → Dashboard, else Profile Setup
            return isComplete ? const DashboardPage() : const ProfileSetupPage();
          },
        );
      },
    );
  }
}