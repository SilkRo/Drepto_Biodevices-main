import 'package:flutter/material.dart';
import 'package:drepto_biodevices/pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:drepto_biodevices/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String _selectedRole = "Patient";
  String? _gender;
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // Patient-specific fields
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();


  // Nurse-specific fields
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  // Official-specific fields
  final TextEditingController _officialRoleController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  final bool _passwordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _licenseNumberController.dispose();
    _specializationController.dispose();
    _availabilityController.dispose();
    _officialRoleController.dispose();
    super.dispose();
  }

  Widget _buildRoleChip(String role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00897B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00897B) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, 
                size: 24,
                color: isSelected ? Colors.white : const Color(0xFF00897B)),
            const SizedBox(height: 6),
            Text(
              role,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF00897B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a gender")),
      );
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the terms and conditions")),
      );
      return;
    }

    setState(() => _loading = true);

    // 1. Collect all data into a map
    final userData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobileNumber': _phoneController.text.trim(),
      'password': _passwordController.text.trim(),
      'gender': _gender,
      'role': _selectedRole,
      // Add role-specific fields based on _selectedRole
    };

    if (_selectedRole == 'Patient') {
      userData.addAll({
        'dateOfBirth': _birthDateController.text.trim(),
        'address': _addressController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
      });
    } else if (_selectedRole == 'Nurse') {
      userData.addAll({
        'licenseNumber': _licenseNumberController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'availability': _availabilityController.text.trim(),
      });
    } else if (_selectedRole == 'Official') {
      userData.addAll({
        'roleTitle': _officialRoleController.text.trim(),
      });
    }

    // 2. Call the API
    try {
      await _apiService.register(userData, _selectedRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please log in.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00897B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildRoleSelector(),
                const SizedBox(height: 24),
                _buildTextField("First Name", _firstNameController),
                const SizedBox(height: 16),
                _buildTextField("Last Name", _lastNameController),
                const SizedBox(height: 16),
                _buildTextField("Email", _emailController, type: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField("Phone Number", _phoneController, type: TextInputType.phone),
                const SizedBox(height: 16),
                _buildPasswordField("Password", _passwordController, isMainPassword: true),
                const SizedBox(height: 16),
                _buildPasswordField("Confirm Password", _confirmPasswordController, isMainPassword: false),
                const SizedBox(height: 16),
                if (_selectedRole == 'Patient') ..._buildPatientFields(),
                if (_selectedRole == 'Nurse') ..._buildNurseFields(),
                if (_selectedRole == 'Official') ..._buildOfficialFields(),
                _buildGenderSelection(),
                const SizedBox(height: 24),
                _buildTermsAndConditions(),
                const SizedBox(height: 24),
                _buildSignupButton(),
                const SizedBox(height: 16),
                _buildLoginRedirect(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 0.5,
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 24),
        Text('Create Account', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF00897B))),
        const SizedBox(height: 8),
        Text('Fill your information below to create an account', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role *',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: ['Patient', 'Nurse', 'Official'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedRole = newValue!;
        });
      },
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }

  List<Widget> _buildPatientFields() {
    return [
      _buildTextField(
        "Date of Birth",
        _birthDateController,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
            });
          }
        },
        validator: (v) => v == null || v.isEmpty ? 'Date of Birth is required' : null,
      ),
      const SizedBox(height: 16),
      _buildTextField("Address", _addressController, maxLines: 2),
      const SizedBox(height: 16),
      _buildTextField("Medical History", _medicalHistoryController, maxLines: 3),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildNurseFields() {
    return [
      _buildTextField("License Number", _licenseNumberController),
      const SizedBox(height: 16),
      _buildTextField("Specialization", _specializationController),
      const SizedBox(height: 16),
      _buildTextField("Availability", _availabilityController),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildOfficialFields() {
    return [
      _buildTextField("Official Role", _officialRoleController),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildGenderSelection() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      hint: const Text('Select Gender'),
      decoration: InputDecoration(
        labelText: 'Gender *',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _gender = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a gender' : null,
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(value: _agreeTerms, onChanged: (value) => setState(() => _agreeTerms = value ?? false)),
        Expanded(child: Text('I agree to the Terms and Conditions and Privacy Policy', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Sign Up', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
            children: [TextSpan(text: 'Login', style: GoogleFonts.poppins(color: const Color(0xFF00897B), fontWeight: FontWeight.w600, fontSize: 14))],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text,
      int maxLines = 1,
      VoidCallback? onTap,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        onTap: onTap,
        readOnly: onTap != null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              if (type == TextInputType.emailAddress && !value.contains('@')) {
                return 'Please enter a valid email';
              }
              if (type == TextInputType.phone &&
                  !RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                return 'Enter a valid 10-digit phone number';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, {required bool isMainPassword}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isMainPassword ? _obscurePassword : _obscureConfirmPassword,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              (isMainPassword ? _obscurePassword : _obscureConfirmPassword)
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                if (isMainPassword) {
                  _obscurePassword = !_obscurePassword;
                } else {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                }
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          if (isMainPassword && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          if (!isMainPassword && value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }
}
