import 'package:flutter/material.dart';
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

    setState(() => _saving = true);

    // TODO: Replace with your own logic to save the profile to your backend.
    // This is a placeholder that simulates a network request.
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    }

    if (mounted) setState(() => _saving = false);
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
