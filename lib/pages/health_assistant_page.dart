import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Nurse Model
class Nurse {
  final String id;
  final String name;
  final String specialization;
  final double rating;
  final int experience;
  final double fee;
  final String imageUrl;
  final List<String> services;

  Nurse({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.experience,
    required this.fee,
    required this.imageUrl,
    required this.services,
  });

  factory Nurse.fromFirestore(Map<String, dynamic> data, String id) {
    return Nurse(
      id: id,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? 'General Nurse',
      rating: (data['rating'] ?? 0.0).toDouble(),
      experience: data['experience'] ?? 0,
      fee: (data['fee'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      services: List<String>.from(data['services'] ?? []),
    );
  }
}

// Enhanced Health Assistant Page
class HealthAssistantPage extends StatefulWidget {
  const HealthAssistantPage({super.key});

  @override
  State<HealthAssistantPage> createState() => _HealthAssistantPageState();
}

class _HealthAssistantPageState extends State<HealthAssistantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _symptomsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Nurse> _nurses = [];
  Nurse? _selectedNurse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNurses();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _nameController.text = userDoc['displayName'] ?? '';
            _phoneController.text = userDoc['phone'] ?? '';
            _addressController.text = userDoc['address'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _loadNurses() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('nurses').where('isAvailable', isEqualTo: true).get();
      setState(() {
        _nurses = querySnapshot.docs.map((doc) => Nurse.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading nurses: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _bookAppointment() {
    if (_formKey.currentState!.validate() && _selectedNurse != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            appointmentData: AppointmentData(
              patientName: _nameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              symptoms: _symptomsController.text,
              date: _selectedDate,
              time: _selectedTime,
              nurse: _selectedNurse!,
            ),
          ),
        ),
      );
    } else if (_selectedNurse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a nurse')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Nurse Appointment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Patient Information'),
                _buildTextField(_nameController, 'Patient Name', validator: (v) => v!.isEmpty ? 'Name is required' : null),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Phone is required' : null),
                const SizedBox(height: 16),
                _buildTextField(_addressController, 'Address', maxLines: 3, validator: (v) => v!.isEmpty ? 'Address is required' : null),
                const SizedBox(height: 24),
                _buildSectionTitle('Appointment Details'),
                _buildTextField(_symptomsController, 'Symptoms/Reason for Visit', maxLines: 3),
                const SizedBox(height: 16),
                _buildNurseSelector(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildDateTimePicker('Date', DateFormat.yMd().format(_selectedDate), () => _selectDate(context))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDateTimePicker('Time', _selectedTime.format(context), () => _selectTime(context))),
                  ],
                ),
                const SizedBox(height: 32),
                _buildPaymentButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildNurseSelector() {
    return GestureDetector(
      onTap: _showNurseSelectionDialog,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8.0)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: _selectedNurse != null ? NetworkImage(_selectedNurse!.imageUrl) : null,
              child: _selectedNurse == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedNurse?.name ?? 'Select a Nurse', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_selectedNurse != null) Text('${_selectedNurse!.specialization} - Exp: ${_selectedNurse!.experience} yrs'),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showNurseSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Nurse'),
        content: SizedBox(
          width: double.maxFinite,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _nurses.length,
                  itemBuilder: (context, index) {
                    final nurse = _nurses[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(nurse.imageUrl)),
                      title: Text(nurse.name),
                      subtitle: Text('${nurse.specialization} - Exp: ${nurse.experience} yrs'),
                      onTap: () {
                        setState(() => _selectedNurse = nurse);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), side: const BorderSide(color: Colors.grey)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value), const Icon(Icons.calendar_today)]),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Data Models
class AppointmentData {
  final String patientName;
  final String phone;
  final String address;
  final String symptoms;
  final DateTime date;
  final TimeOfDay time;
  final Nurse nurse;

  AppointmentData({
    required this.patientName,
    required this.phone,
    required this.address,
    required this.symptoms,
    required this.date,
    required this.time,
    required this.nurse,
  });
}

class PaymentData {
  final String appointmentId;
  final double amount;
  final String nurseName;
  final DateTime date;
  final String patientName;

  PaymentData({
    required this.appointmentId,
    required this.amount,
    required this.nurseName,
    required this.date,
    required this.patientName,
  });
}

// Payment Page
class PaymentPage extends StatefulWidget {
  final AppointmentData appointmentData;

  const PaymentPage({super.key, required this.appointmentData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Save appointment to Firebase
      final appointmentId = await _saveAppointmentToFirebase();

      // Send confirmation notification
      await _sendConfirmationNotification(appointmentId);

      // Show success dialog
      _showSuccessDialog(appointmentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String> _saveAppointmentToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final appointmentId = const Uuid().v4();
    final appointmentData = {
      'appointmentId': appointmentId,
      'userId': user.uid,
      'patientName': widget.appointmentData.patientName,
      'phone': widget.appointmentData.phone,
      'address': widget.appointmentData.address,
      'symptoms': widget.appointmentData.symptoms,
      'date': Timestamp.fromDate(widget.appointmentData.date),
      'time': widget.appointmentData.time.format(context),
      'nurseId': widget.appointmentData.nurse.id,
      'nurseName': widget.appointmentData.nurse.name,
      'nurseSpecialization': widget.appointmentData.nurse.specialization,
      'fee': widget.appointmentData.nurse.fee,
      'status': 'confirmed',
      'paymentMethod': _selectedPaymentMethod,
      'paymentStatus': 'paid',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .set(appointmentData);

    return appointmentId;
  }

  Future<void> _sendConfirmationNotification(String appointmentId) async {
    // In a real app, you would send this to your backend
    // For demo, we'll just show a local notification
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save notification to user's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Appointment Confirmed',
        'body': 'Your nurse appointment with ${widget.appointmentData.nurse.name} has been confirmed for ${DateFormat('MMM dd, yyyy').format(widget.appointmentData.date)} at ${widget.appointmentData.time.format(context)}',
        'type': 'appointment_confirmation',
        'appointmentId': appointmentId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showSuccessDialog(String appointmentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appointment ID: $appointmentId'),
              const SizedBox(height: 10),
              Text('Nurse: ${widget.appointmentData.nurse.name}'),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(widget.appointmentData.date)}'),
              Text('Time: ${widget.appointmentData.time.format(context)}'),
              Text('Amount: \$${widget.appointmentData.nurse.fee}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentDetailsPage(
                      appointmentId: appointmentId,
                    ),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFFFFF4EF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appointment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(),
                    ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(widget.appointmentData.nurse.imageUrl)),
                      title: Text(widget.appointmentData.nurse.name),
                      subtitle: Text(widget.appointmentData.nurse.specialization),
                      trailing: Text('\$${widget.appointmentData.nurse.fee}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    Text('Date: ${DateFormat('MMM dd, yyyy').format(widget.appointmentData.date)} at ${widget.appointmentData.time.format(context)}'),
                    const SizedBox(height: 8),
                    Text('Patient: ${widget.appointmentData.patientName}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment Method
            const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            RadioListTile<String>(
              title: const Text('Credit/Debit Card'),
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            ),
            RadioListTile<String>(
              title: const Text('PayPal'),
              value: 'paypal',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            ),
            RadioListTile<String>(
              title: const Text('Google Pay'),
              value: 'google_pay',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            ),
            const Spacer(),
            // Process Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Pay Now', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Appointment Details Page (Placeholder)
class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  Map<String, dynamic>? appointmentDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  Future<void> _fetchAppointmentDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
      if (doc.exists) {
        setState(() {
          appointmentDetails = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Handle case where appointment is not found
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointmentDetails == null
              ? const Center(child: Text('Appointment not found.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('Appointment ID'),
                        subtitle: Text(widget.appointmentId),
                      ),
                      ListTile(
                        title: const Text('Patient Name'),
                        subtitle: Text(appointmentDetails!['patientName']),
                      ),
                      ListTile(
                        title: const Text('Nurse Name'),
                        subtitle: Text(appointmentDetails!['nurseName']),
                      ),
                      ListTile(
                        title: const Text('Date & Time'),
                        subtitle: Text('${appointmentDetails!['date'] is Timestamp ? DateFormat('MMM dd, yyyy').format((appointmentDetails!['date'] as Timestamp).toDate()) : ''} at ${appointmentDetails!['time']}'),
                      ),
                       ListTile(
                        title: const Text('Status'),
                        subtitle: Text(appointmentDetails!['status']),
                      ),
                       ListTile(
                        title: const Text('Fee'),
                        subtitle: Text('\$${appointmentDetails!['fee']}'),
                      ),
                    ],
                  ),
                ),
    );
  }
}