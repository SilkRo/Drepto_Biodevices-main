import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'pharmacy_page.dart';
import 'lab_test_page.dart';
import 'doctor_booking_page.dart';
import 'insurance_page.dart';
import 'select_page.dart';
import 'health_records_page.dart';
import 'circle_membership_page.dart';
import 'appointment_history_page.dart';
import 'health_assistant_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "User";
  String userAddress = "Some Address";
  String userRole = "Patient";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }


  Future<void> _loadUserProfile() async {
    // TODO: Replace with your own logic to load the user profile from your backend.
    // This is placeholder data.
    setState(() {
      userName = "Test User";
      userAddress = "123 Flutter Lane";
      userRole = "Patient";
    });
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
    // TODO: Add any token clearing logic here.
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
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
                    GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const Icon(Icons.account_circle_outlined, color: Colors.black),
          ),
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
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PharmacyPage()),
                    ),
                    child: dashboardItem(Icons.local_pharmacy, "Drepto\nPharmacy"),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LabTestPage()),
                    ),
                    child: dashboardItem(Icons.bloodtype, "Lab-Test\n@ Home"),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorBookingPage()),
                    ),
                    child: dashboardItem(Icons.medical_services, "Doctor\nBooking"),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InsurancePage()),
                    ),
                    child: dashboardItem(Icons.verified_user, "Health\nInsurance"),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectPage()),
                    ),
                    child: dashboardItem(Icons.credit_card, "Drepto\nSELECT"),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HealthRecordsPage()),
                    ),
                    child: dashboardItem(Icons.folder, "Health\nRecords"),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CircleMembershipPage()),
                    ),
                    child: dashboardItem(Icons.group, "Circle\nMembership"),
                  ),
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
