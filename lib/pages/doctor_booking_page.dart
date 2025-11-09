import 'package:flutter/material.dart';

class DoctorBookingPage extends StatelessWidget {
  const DoctorBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Booking'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Doctor booking feature coming soon')),
    );
  }
}
