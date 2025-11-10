import 'package:flutter/material.dart';
import 'package:drepto_biodevices/api_service.dart';
import 'package:drepto_biodevices/secure_storage_service.dart';

class DoctorBookingPage extends StatefulWidget {
  const DoctorBookingPage({super.key});

  @override
  State<DoctorBookingPage> createState() => _DoctorBookingPageState();
}

class _DoctorBookingPageState extends State<DoctorBookingPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _nursesFuture;

  @override
  void initState() {
    super.initState();
    _nursesFuture = _fetchNurses();
  }

  Future<List<dynamic>> _fetchNurses() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      // Handle case where token is not available, maybe navigate to login
      throw Exception('Authentication token not found.');
    }
    return _apiService.getAllNurses(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Nurse'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _nursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No nurses found.'));
          }

          final nurses = snapshot.data!;

          return ListView.builder(
            itemCount: nurses.length,
            itemBuilder: (context, index) {
              final nurse = nurses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    // You can use a placeholder or a network image if available
                    child: Text(nurse['firstName']?[0] ?? 'N'),
                  ),
                  title: Text('${nurse['firstName']} ${nurse['lastName']}'),
                  subtitle: Text(nurse['specialization'] ?? 'No specialization'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement booking logic
                      // This will likely navigate to a confirmation page
                      // and then call the createAppointment API.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Booking ${nurse['firstName']}... (Not implemented)')),
                      );
                    },
                    child: const Text('Book'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

