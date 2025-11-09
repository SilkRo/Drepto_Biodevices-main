import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String _selectedRole = "Patient";
  String? _gender;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // Doctor-specific
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _registrationNoController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Official-specific
  final TextEditingController _officialRoleController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();

    // Doctor
    _specializationController.dispose();
    _registrationNoController.dispose();
    _experienceController.dispose();

    // Official
    _officialRoleController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Widget _buildRoleSelector(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
            child: Icon(icon, color: isSelected ? Colors.blue : Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select gender")),
      );
      return;
    }

    // Extra validation for roles
    if (_selectedRole == "Doctor") {
      if (_specializationController.text.trim().isEmpty ||
          _registrationNoController.text.trim().isEmpty ||
          _experienceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor fields are required")),
        );
        return;
      }
    }
    if (_selectedRole == "Official") {
      if (_officialRoleController.text.trim().isEmpty ||
          _accessCodeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Official fields are required")),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "birthDate": _birthDateController.text.trim(),
        "gender": _gender,
        "role": _selectedRole,
        if (_selectedRole == "Doctor") ...{
          "specialization": _specializationController.text.trim(),
          "registrationNo": _registrationNoController.text.trim(),
          "experience": _experienceController.text.trim(),
        },
        if (_selectedRole == "Official") ...{
          "officialRole": _officialRoleController.text.trim(),
          "accessCode": _accessCodeController.text.trim(),
        },
        "createdAt": FieldValue.serverTimestamp(),
        "isProfileComplete": false,
      });

      if (mounted) {
        // Just pop the signup screen, AuthWrapper will handle the rest
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Signup failed";
      if (e.code == 'email-already-in-use') {
        msg = "Email already in use";
      } else if (e.code == 'invalid-email') {
        msg = "Invalid email format";
      } else if (e.code == 'weak-password') {
        msg = "Password is too weak";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRoleSelector("Patient", Icons.person),
                    const SizedBox(width: 20),
                    _buildRoleSelector("Doctor", Icons.medical_services),
                    const SizedBox(width: 20),
                    _buildRoleSelector("Official", Icons.verified_user),
                  ],
                ),
                const SizedBox(height: 20),

                // Common Fields
                _buildTextField("First Name *", _firstNameController),
                _buildTextField("Last Name *", _lastNameController),
                _buildTextField("Email *", _emailController,
                    type: TextInputType.emailAddress),
                _buildTextField("Phone Number *", _phoneController,
                    type: TextInputType.phone),
                _buildPasswordField("Password *", _passwordController),
                _buildPasswordField("Confirm Password *",
                    _confirmPasswordController, checkConfirm: true),

                // Birth Date
                const Text("Birth Date *"),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Select your birth date (yyyy-mm-dd)",
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      _birthDateController.text =
                          pickedDate.toIso8601String().split('T').first;
                    }
                  },
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 12),

                // Gender
                const Text("Gender *"),
                Row(
                  children: [
                    Radio<String>(
                      value: "Male",
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const Text("Male"),
                    Radio<String>(
                      value: "Female",
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const Text("Female"),
                  ],
                ),

                // Doctor Fields
                if (_selectedRole == "Doctor") ...[
                  _buildTextField("Specialization *", _specializationController),
                  _buildTextField("Registration Number *", _registrationNoController),
                  _buildTextField("Years of Experience *", _experienceController,
                      type: TextInputType.number),
                ],

                // Official Fields
                if (_selectedRole == "Official") ...[
                  _buildTextField("Official Role Title *", _officialRoleController),
                  _buildPasswordField("Access Code *", _accessCodeController),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Register"),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Sign in",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for normal text field
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: label,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
        ),
      ],
    );
  }

  // Helper widget for password field
  Widget _buildPasswordField(String label, TextEditingController controller,
      {bool checkConfirm = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: label,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return "Required";
            if (checkConfirm && v != _passwordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
      ],
    );
  }
}