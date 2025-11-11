import 'package:flutter/material.dart';
import 'package:drepto_biodevices/api_service.dart';
import 'package:drepto_biodevices/secure_storage_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final token = await SecureStorageService.getToken();
      final userId = await SecureStorageService.getUserId();

      if (token != null && userId != null) {
        final userData = await _apiService.getSingleUser(userId, token);
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        throw Exception('User not authenticated.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('No profile data found.'))
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildDetailsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(Icons.person, size: 48, color: Color(0xFF00897B)),
        ),
        const SizedBox(height: 12),
        Text(
          '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _userData?['email'] ?? 'N/A',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _row(Icons.badge_outlined, 'Role', _userData?['role'] ?? 'N/A'),
            const Divider(height: 24),
            _row(Icons.phone_outlined, 'Phone', _userData?['phoneNumber'] ?? 'N/A'),
            const Divider(height: 24),
            _row(Icons.home_outlined, 'Address', _userData?['address'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00897B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: Colors.grey.shade800)),
            ],
          ),
        ),
      ],
    );
  }
}
