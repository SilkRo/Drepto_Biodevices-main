import 'package:flutter/material.dart';

class LabTestPage extends StatelessWidget {
  const LabTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab-Test @ Home'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Lab tests feature coming soon')),
    );
  }
}
