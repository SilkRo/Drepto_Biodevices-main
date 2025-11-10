import 'package:flutter/material.dart';
import 'package:drepto_biodevices/api_service.dart';
import 'package:drepto_biodevices/secure_storage_service.dart';
import 'package:intl/intl.dart';

class AppointmentHistoryPage extends StatefulWidget {
  const AppointmentHistoryPage({super.key});

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _fetchAppointments();
  }

  Future<List<dynamic>> _fetchAppointments() async {
    final token = await SecureStorageService.getToken();
    final userId = await SecureStorageService.getUserId();
    if (token == null || userId == null) {
      throw Exception('User not authenticated.');
    }
    return _apiService.getAppointments(userId, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment History'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No appointments found.'));
          }

          final appointments = snapshot.data!;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              // Assuming your appointment object has these fields.
              // Adjust the keys based on your actual API response.
              final nurseName = appointment['nurseId']?['firstName'] ?? 'N/A';
              final date = appointment['date'] != null
                  ? DateFormat('MMM dd, yyyy').format(DateTime.parse(appointment['date']))
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('Appointment with $nurseName'),
                  subtitle: Text('On $date'),
                  trailing: Text(appointment['status'] ?? 'Unknown'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

