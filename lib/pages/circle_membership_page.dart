import 'package:flutter/material.dart';

class CircleMembershipPage extends StatelessWidget {
  const CircleMembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle Membership'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Circle membership feature coming soon')),
    );
  }
}
