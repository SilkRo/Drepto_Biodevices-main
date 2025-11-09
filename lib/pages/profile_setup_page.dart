import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedRole = "Patient";

  bool _saving = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not logged in")),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "displayName": _displayNameController.text.trim(),
        "address": _addressController.text.trim(),
        "role": _selectedRole!.toLowerCase(),
        "updatedAt": FieldValue.serverTimestamp(),
        "isProfileComplete": true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Setup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Display Name *",
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Address *",
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Role
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Role *",
                ),
                items: ["Patient", "Doctor", "Official"]
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a role' : null,
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save & Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
