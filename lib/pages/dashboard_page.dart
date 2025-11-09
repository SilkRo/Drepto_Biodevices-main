import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "Loading...";
  String userAddress = "";
  String userRole = "";
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _setupPushNotifications();
  }

  Future<void> _setupPushNotifications() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get token
      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");

      // Save token to user profile
      await _saveFCMToken(token);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          _showNotificationDialog(
            message.notification!.title ?? 'Notification',
            message.notification!.body ?? 'You have a new notification',
          );
        }
      });
    }
  }

  Future<void> _saveFCMToken(String? token) async {
    if (token != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'fcmTokenUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['displayName'] ?? "User";
            userAddress = userDoc['address'] ?? "";
            userRole = userDoc['role'] ?? "";
          });
        }
      }
    } catch (e) {
      setState(() {
        userName = "Error loading";
        userAddress = "";
        userRole = "";
      });
      debugPrint("Error fetching profile: $e");
    }
  }

  void _navigateToHealthAssistant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthAssistantPage()),
    );
  }

  void _navigateToAppointmentHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointmentHistoryPage()),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // The AuthWrapper will automatically handle the navigation to login page
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error signing out. Please try again.')),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Namaste $userName",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            if (userAddress.isNotEmpty)
              Text(userAddress, style: const TextStyle(fontSize: 13)),
            if (userRole.isNotEmpty)
              Text("Role: $userRole",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () => _navigateToAppointmentHistory(context),
            tooltip: 'Appointment History',
          ),
          const Icon(Icons.notifications_none, color: Colors.black),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
          const Icon(Icons.account_circle_outlined, color: Colors.black),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Insurance",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.shopping_cart_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Category Tabs
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  categoryTab("ALL", isSelected: true),
                  categoryTab("Personal Care"),
                  categoryTab("Baby Carnival"),
                  categoryTab("Nutrition"),
                  categoryTab("50% OFF"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Banner Ad
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Skincredible Sale - Banner",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Icon Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  dashboardItem(Icons.local_pharmacy, "Drepto\nPharmacy"),
                  dashboardItem(Icons.bloodtype, "Lab-Test\n@ Home"),
                  dashboardItem(Icons.medical_services, "Doctor\nBooking"),
                  dashboardItem(Icons.verified_user, "Health\nInsurance"),
                  dashboardItem(Icons.credit_card, "Drepto\nSELECT"),
                  dashboardItem(Icons.folder, "Health\nRecords"),
                  dashboardItem(Icons.group, "Circle\nMembership"),
                  GestureDetector(
                    onTap: () => _navigateToHealthAssistant(context),
                    child: dashboardItem(Icons.smart_toy, "Health\nAssistant"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Promotional Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Frustrated trying\nto lose weight?",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text("Let's treat obesity better."),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Icon(Icons.accessibility_new,
                        size: 40, color: Colors.pink),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF00897B), // Teal from logo
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: "Doctors"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy), label: "Pharmacy"),
          BottomNavigationBarItem(
              icon: Icon(Icons.science), label: "Lab Tests"),
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety), label: "Insurance"),
        ],
      ),
    );
  }

  Widget categoryTab(String text, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00897B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF00897B) : Colors.grey),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF00897B),
        ),
      ),
    );
  }

  Widget dashboardItem(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F1), // Light teal background
          radius: 26,
          child: Icon(icon, size: 28, color: const Color(0xFF00897B)), // Teal from logo
        ),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

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
                    const Text(
                      'Appointment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                        NetworkImage(widget.appointmentData.nurse.imageUrl),
                      ),
                      title: Text(widget.appointmentData.nurse.name),
                      subtitle: Text(widget.appointmentData.nurse.specialization),
                      trailing: Text(
                        '\$${widget.appointmentData.nurse.fee}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const Divider(),
                    Text('Date: ${DateFormat('MMM dd, yyyy').format(widget.appointmentData.date)}'),
                    Text('Time: ${widget.appointmentData.time.format(context)}'),
                    Text('Patient: ${widget.appointmentData.patientName}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Methods
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            RadioListTile<String>(
              title: const Text('Credit/Debit Card'),
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('UPI Payment'),
              value: 'upi',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Net Banking'),
              value: 'netbanking',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),

            const Spacer(),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Appointment History Page
class AppointmentHistoryPage extends StatefulWidget {
  const AppointmentHistoryPage({super.key});

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> {
  List<QueryDocumentSnapshot> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .get();

        setState(() {
          _appointments = querySnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading appointments: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment History'),
        backgroundColor: const Color(0xFFFFF4EF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? const Center(
        child: Text(
          'No appointments found',
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _appointments.length,
          itemBuilder: (context, index) {
            final appointment = _appointments[index];
            final data = appointment.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final time = data['time'] as String;
            final status = data['status'] as String;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status),
                  child: const Icon(Icons.medical_services,
                      color: Colors.white, size: 20),
                ),
                title: Text(data['nurseName'] ?? 'Nurse'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${DateFormat('MMM dd, yyyy').format(date)} at $time'),
                    Text('Fee: \$${data['fee'] ?? '0'}'),
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(status),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailsPage(
                        appointmentId: data['appointmentId'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// Appointment Details Page
class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  Map<String, dynamic>? _appointmentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (doc.exists) {
        setState(() {
          _appointmentData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading appointment details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh data
      _loadAppointmentDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_appointmentData == null) {
      return const Scaffold(
        body: Center(child: Text('Appointment not found')),
      );
    }

    final data = _appointmentData!;
    final date = (data['date'] as Timestamp).toDate();
    final status = data['status'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFFFFF4EF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Appointment ID', data['appointmentId']),
                    _buildDetailRow('Status', status,
                        isStatus: true),
                    _buildDetailRow('Date',
                        DateFormat('MMM dd, yyyy').format(date)),
                    _buildDetailRow('Time', data['time']),
                    _buildDetailRow('Nurse', data['nurseName']),
                    _buildDetailRow('Specialization',
                        data['nurseSpecialization']),
                    _buildDetailRow('Fee', '\$${data['fee']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Name', data['patientName']),
                    _buildDetailRow('Phone', data['phone']),
                    _buildDetailRow('Address', data['address']),
                    _buildDetailRow('Symptoms', data['symptoms']),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (status == 'confirmed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cancelAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Appointment'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isStatus
                ? Chip(
              label: Text(
                value.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getStatusColor(value),
            )
                : Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Firestore Data Setup (Run this once to create sample nurses)
/*
Future<void> setupSampleNurses() async {
  final nurses = [
    {
      'name': 'Sarah Johnson',
      'specialization': 'Registered Nurse',
      'rating': 4.8,
      'experience': 8,
      'fee': 50.0,
      'imageUrl': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150',
      'services': ['Wound Care', 'Medication Administration', 'Health Assessment'],
      'isAvailable': true,
    },
    {
      'name': 'Michael Chen',
      'specialization': 'Critical Care Nurse',
      'rating': 4.9,
      'experience': 12,
      'fee': 75.0,
      'imageUrl': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=150',
      'services': ['Emergency Care', 'Patient Monitoring', 'IV Therapy'],
      'isAvailable': true,
    },
    {
      'name': 'Emily Davis',
      'specialization': 'Pediatric Nurse',
      'rating': 4.7,
      'experience': 6,
      'fee': 60.0,
      'imageUrl': 'https://images.unsplash.com/photo-1594824947933-d0501ba2fe65?w=150',
      'services': ['Child Care', 'Vaccination', 'Growth Monitoring'],
      'isAvailable': true,
    },
  ];

  final firestore = FirebaseFirestore.instance;
  for (var nurse in nurses) {
    await firestore.collection('nurses').add(nurse);
  }
}
*/