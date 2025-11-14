import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Replace with your actual VM's static IP address or domain name.
  static const String _baseUrl = 'http://34.100.159.39:6001';

  // Example headers. You might need to add an Authorization header for authenticated requests.
  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  /// Logs in a user with the given email and password.
  ///
  /// Returns a map with user data and a token on success.
  /// Throws an exception if the login fails.
  Future<Map<String, dynamic>> login(String email, String password, String role) async {
    // Note: Your login endpoints are /login/user, /login/nurse, etc.
    // The role from the UI is 'Patient', 'Nurse', etc.
    // We need to convert it to lowercase to match the endpoint.
    final endpoint = role.toLowerCase() == 'official' ? 'authorized' : role.toLowerCase();

    final response = await http.post(
      Uri.parse('$_baseUrl/login/$endpoint'),
      headers: _headers,
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    // Log the full response body for debugging
    print('Login response: ${response.body}');

    final responseBody = jsonDecode(response.body);

    // TEMPORARY WORKAROUND: Check for success field in the body because the API
    // is returning a non-200 status code on successful login.
    // The backend should be fixed to return a 200 status code and a token.
    if (response.statusCode == 200 || responseBody['success'] == true) {
      // Normalize possible shapes into a consistent map with 'token' and 'user'.
      String? token = responseBody['token'] as String?;
      if (token == null && responseBody is Map && responseBody['data'] is Map) {
        final data = responseBody['data'] as Map;
        token = data['token'] as String?;
      }

      dynamic userObj = responseBody['user'];
      if (userObj == null && responseBody is Map && responseBody['data'] is Map) {
        final data = responseBody['data'] as Map;
        userObj = data['user'];
      }

      final Map<String, dynamic>? user =
          (userObj is Map) ? Map<String, dynamic>.from(userObj) : null;

      // Try to extract a userId from multiple possible shapes
      String? userId;
      if (user != null) {
        userId = (user['_id'] ?? user['id'] ?? user['userId'] ?? user['uid']) as String?;
      }
      if (userId == null && responseBody is Map) {
        // Check top-level fields
        userId = (responseBody['_id'] ?? responseBody['id'] ?? responseBody['userId'] ?? responseBody['uid']) as String?;
      }
      if (userId == null && responseBody is Map && responseBody['data'] is Map) {
        final data = responseBody['data'] as Map;
        userId = (data['_id'] ?? data['id'] ?? data['userId'] ?? data['uid']) as String?;
      }

      // Add a placeholder token if it's missing, so the app doesn't crash.
      token ??= 'placeholder_token_backend_missing_it';

      return {
        'token': token,
        'user': user,
        'userId': userId,
        'raw': responseBody,
      };
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception with the error message.
      // You might want to parse the error response for a more specific message.
      throw Exception('Failed to login: ${response.body}');
    }
  }

  /// Registers a new user with the provided data.
  ///
  /// The `userData` map should contain all the necessary registration fields
  /// like firstName, lastName, email, password, role, etc.
  /// Returns the newly created user's data.
  /// Throws an exception if registration fails.
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData, String role) async {
    // Map the UI role to the API endpoint
    String endpoint;
    switch (role) {
      case 'Patient':
        endpoint = 'user';
        break;
      case 'Nurse':
        endpoint = 'nurse';
        break;
      case 'Official':
        endpoint = 'authorized';
        break;
      default:
        throw Exception('Invalid role specified');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) { // 201 Created is a common success status for POST
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // Helper method to get authenticated headers
  Map<String, String> _getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches all appointments for a given user.
  Future<List<dynamic>> getAppointments(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/appointments/$userId'),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointments: ${response.body}');
    }
  }

  /// Creates a new appointment.
  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/appointments'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(appointmentData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create appointment: ${response.body}');
    }
  }

  /// Fetches a list of all users.
  Future<List<dynamic>> getAllUsers(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Allusers'),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  /// Fetches a single user by their ID.
  Future<Map<String, dynamic>> getSingleUser(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user/$userId'),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  /// Fetches the details of a single appointment.
  Future<Map<String, dynamic>> getAppointmentDetails(String appointmentId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/appointment/$appointmentId'), // Assuming this is the correct endpoint
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointment details: ${response.body}');
    }
  }

  /// Fetches a list of all nurses.
  Future<List<dynamic>> getAllNurses(String token) async {
    final uri = Uri.parse('$_baseUrl/Allnurse');
    // Debug
    print('GET $uri');

    final response = await http.get(
      uri,
      headers: _getAuthHeaders(token),
    );

    // Debug
    // print('Allnurse status: ${response.statusCode}');
    // print('Allnurse body: ${response.body}');

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode == 200) {
      if (body is List) return body;
      if (body is Map && body['nurses'] is List) return body['nurses'] as List<dynamic>;
      if (body is Map && body['data'] is List) return body['data'] as List<dynamic>;
      if (body is Map && body['success'] == true && body['data'] is List) return body['data'] as List<dynamic>;
      return [];
    }

    // Some backends return non-200 with success flag
    if (body is Map && body['success'] == true) {
      if (body['nurses'] is List) return body['nurses'] as List<dynamic>;
      if (body['data'] is List) return body['data'] as List<dynamic>;
    }

    final message = (body is Map && body['message'] is String)
        ? body['message'] as String
        : 'HTTP ${response.statusCode}';
    throw Exception('Failed to load nurses: $message');
  }
}