import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // We will create this next
import 'dashboard_page.dart';
import 'profile_setup_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Check connection state for auth stream
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If user is not logged in, go to LoginPage
        if (authSnapshot.data == null) {
          return const LoginPage();
        }

        // User is logged in, now check Firestore for profile completion
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, firestoreSnapshot) {
            // Check connection state for Firestore stream
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Check if document exists and get data
            if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
              final userData = firestoreSnapshot.data!.data() as Map<String, dynamic>;

              // If profile is complete, go to Dashboard
              if (userData['isProfileComplete'] == true) {
                return const DashboardPage();
              } else {
                // Profile is not complete, go to ProfileSetupPage
                return const ProfileSetupPage();
              }
            } else {
              // Document doesn't exist, which shouldn't normally happen, but handle it by going to profile setup
              return const ProfileSetupPage();
            }
          },
        );
      },
    );
  }
}