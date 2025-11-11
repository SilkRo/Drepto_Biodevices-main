import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drepto_biodevices/api_service.dart';
import 'package:drepto_biodevices/secure_storage_service.dart';

// Nurse Model adapted for API response
class Nurse {
  final String id;
  final String firstName;
  final String lastName;
  final String specialization;
  final String gender;
  final String availability; // e.g., 'Per Day', 'Per Week', 'Per Month'
  // Add other fields as per your API response, e.g., imageUrl, fee, etc.

  Nurse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    required this.gender,
    required this.availability,
  });

  factory Nurse.fromJson(Map<String, dynamic> json) {
    return Nurse(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      specialization: json['specialization'] ?? 'General Nurse',
      gender: json['gender'] ?? 'Female', // Defaulting to Female for example
      availability: json['availability'] ?? 'Per Day',
    );
  }

  String get fullName => '$firstName $lastName';
}

// Health Assistant Page using ApiService
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
  List<Nurse> _filteredNurses = [];
  Nurse? _selectedNurse;
  bool _isLoadingNurses = true;
  bool _isBooking = false;

  // Filter state
  String? _selectedDuration; // start with no duration filter
  String? _selectedGender; // start with no gender filter
  String? _selectedSpecialization; // start with no specialization filter
  List<String> _specializations = [
    'Nurse Practitioner (NP)',
    'Clinical Nurse Specialist (CNS)',
    'Nurse Anesthetist (CRNA)',
    'Nurse Midwife (CNM)',
    'Pediatric Nurse',
    'Neonatal Nurse',
    'Geriatric Nurse',
    'Family Nurse Practitioner (FNP)',
    'Psychiatric Mental Health Nurse',
    'Oncology Nurse',
    'Cardiac Nurse',
    'Orthopedic Nurse',
    'Diabetes Management Nurse',
    'Pain Management Nurse',
    'Emergency Room (ER) Nurse',
    'Trauma Nurse',
    'Critical Care Nurse (ICU)',
    'Surgical/Operating Room Nurse',
    'Public Health Nurse',
    'Nurse Educator',
    'Nurse Researcher',
    'Legal Nurse Consultant',
    'Informatics Nurse',
    'Travel Nurse',
  ];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadUserData();
    await _loadNurses();
  }

  Future<void> _loadUserData() async {
    try {
      final token = await SecureStorageService.getToken();
      final userId = await SecureStorageService.getUserId();
      if (token != null && userId != null) {
        final user = await _apiService.getSingleUser(userId, token);
        setState(() {
          _nameController.text = '${user['firstName']} ${user['lastName']}';
          _phoneController.text = user['phoneNumber'] ?? '';
          _addressController.text = user['address'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadNurses() async {
    setState(() => _isLoadingNurses = true);
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      final dynamic nursesData = await _apiService.getAllNurses(token);

      // Normalize possible response shapes
      List<dynamic> list;
      if (nursesData is List) {
        list = nursesData;
      } else if (nursesData is Map && nursesData['nurses'] is List) {
        list = nursesData['nurses'] as List<dynamic>;
      } else if (nursesData is Map && nursesData['data'] is List) {
        list = nursesData['data'] as List<dynamic>;
      } else {
        list = [];
      }

      // Debug
      // ignore: avoid_print
      print('Nurses fetched: count=${list.length}');
      if (list.isNotEmpty) {
        // ignore: avoid_print
        print('Sample nurse: ${list.first}');
      }

      setState(() {
        _nurses = list.map((data) => Nurse.fromJson(data as Map<String, dynamic>)).toList();
        _applyFilters(); // Apply initial filters
        _isLoadingNurses = false;
      });

      if (_nurses.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No nurses returned by the server.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load nurses: ${e.toString()}')),
        );
      }
      setState(() => _isLoadingNurses = false);
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

  void _applyFilters() {
    setState(() {
      _filteredNurses = _nurses.where((nurse) {
        final genderMatch = _selectedGender == null ||
            nurse.gender.toLowerCase() == _selectedGender!.toLowerCase();
        final specializationMatch = _selectedSpecialization == null ||
            nurse.specialization.toLowerCase().contains(_selectedSpecialization!.toLowerCase());
        final durationMatch = _selectedDuration == null ||
            nurse.availability.toLowerCase().contains(_selectedDuration!.toLowerCase());
        return genderMatch && specializationMatch && durationMatch;
      }).toList();
      // Reset selected nurse if they are no longer in the filtered list
      if (_selectedNurse != null && !_filteredNurses.contains(_selectedNurse)) {
        _selectedNurse = null;
      }
    });
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedNurse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a nurse.')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final token = await SecureStorageService.getToken();
      final userId = await SecureStorageService.getUserId();
      if (token == null || userId == null) {
        throw Exception('User not authenticated.');
      }

      final appointmentData = {
        'patientId': userId,
        'nurseId': _selectedNurse!.id,
        'date': _selectedDate.toIso8601String(),
        'time': _selectedTime.format(context),
        'symptoms': _symptomsController.text,
        'patientDetails': {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        }
      };

      await _apiService.createAppointment(appointmentData, token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        Navigator.of(context).pop(); // Go back to the dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book appointment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Nurse Appointment'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
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
                const SizedBox(height: 24),
                _buildSectionTitle('Service Options'),
                _buildDurationFilter(),
                const SizedBox(height: 16),
                _buildSectionTitle('Filter Nurses'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDuration = null;
                          _selectedGender = null;
                          _selectedSpecialization = null;
                          _applyFilters();
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
                _buildGenderFilter(),
                const SizedBox(height: 16),
                _buildSpecializationFilter(),
                const SizedBox(height: 24),
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
                _buildBookingButton(),
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
            const CircleAvatar(child: Icon(Icons.person)), // Placeholder icon
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedNurse?.fullName ?? 'Select a Nurse', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_selectedNurse != null) Text(_selectedNurse!.specialization),
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _isLoadingNurses
            ? const Center(child: CircularProgressIndicator())
            : _filteredNurses.isEmpty
                ? const Center(child: Text('No nurses match the selected filters.'))
                : ListView.builder(
                    itemCount: _filteredNurses.length,
                    itemBuilder: (context, index) {
                      final nurse = _filteredNurses[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(nurse.fullName),
                        subtitle: Text('${nurse.specialization} • ${nurse.gender} • ${nurse.availability}'),
                        onTap: () {
                          setState(() => _selectedNurse = nurse);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
      },
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onPressed,
          child: Row(
            children: [const Icon(Icons.calendar_today), const SizedBox(width: 8), Text(value)],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationFilter() {
    return Wrap(
      spacing: 8.0,
      children: ['Per Day', 'Per Week', 'Per Month'].map((duration) {
        return ChoiceChip(
          label: Text(duration),
          selected: _selectedDuration == duration,
          onSelected: (selected) {
            setState(() {
              _selectedDuration = selected ? duration : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGenderFilter() {
    return Wrap(
      spacing: 8.0,
      children: ['Male', 'Female'].map((gender) {
        return ChoiceChip(
          label: Text(gender),
          selected: _selectedGender == gender,
          onSelected: (selected) {
            setState(() {
              _selectedGender = selected ? gender : null;
              _applyFilters();
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSpecializationFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedSpecialization,
      hint: const Text('Select Specialization'),
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: _specializations.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedSpecialization = newValue;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildBookingButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isBooking ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        child: _isBooking
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Confirm Booking'),
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
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? appointmentDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  Future<void> _fetchAppointmentDetails() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token != null) {
        final appointmentData = await _apiService.getAppointmentDetails(widget.appointmentId, token);
        setState(() {
          appointmentDetails = appointmentData;
          isLoading = false;
        });
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
                        subtitle: Text(appointmentDetails!['patientDetails']['name']),
                      ),
                      ListTile(
                        title: const Text('Nurse Name'),
                        subtitle: Text(appointmentDetails!['nurseName']),
                      ),
                      ListTile(
                        title: const Text('Date & Time'),
                        subtitle: Text('${appointmentDetails!['date']} at ${appointmentDetails!['time']}'),
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