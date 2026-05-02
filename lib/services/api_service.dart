import 'dart:convert';
import 'package:http/http.dart' as http;

// =============================================================
// API SERVICE  (Singleton)
// Responsibilities:
//   - Manage the single HTTP client instance
//   - Provide typed methods for every backend endpoint
//   - Send X-App-Source: mobile header on every request so the
//     backend automatically assigns the 'client' role
//   - Isolate all network logic from UI pages
// OOP Principle: Singleton, Encapsulation, Abstraction
// =============================================================
class ApiService {
  // --- Singleton setup ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- Configuration ---
  // Replace 192.168.x.x with your PC's local IP address
  // Run `ipconfig` (Windows) or `hostname -I` (Linux/Mac) to find it
  // Your phone and PC must be on the same WiFi network
  static const String _baseUrl = 'http://109.199.120.38:5000/api';

  // X-App-Source header tells the backend this request comes from
  // the mobile app → role will be automatically set to 'client'
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'X-App-Source': 'mobile',
  };

  // ----------------------------------------------------------
  // REGISTER
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _post('/register', {
      'username': username,
      'email':    email,
      'password': password,
    });
  }

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _post('/login', {
      'email':    email,
      'password': password,
    }, includeStatusCode: true);
  }

  // ----------------------------------------------------------
  // VERIFY EMAIL
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    return _post('/verify-email', {
      'email': email,
      'code':  code,
    });
  }

  // ----------------------------------------------------------
  // RESEND OTP
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    return _post('/resend-otp', {'email': email});
  }
// ----------------------------------------------------------
// CREATE TICKET
// ----------------------------------------------------------
Future<Map<String, dynamic>> createTicket({
  required String userId,
  required String title,
  required String description,
  required String notes,
  required String priority,
  required String service,
  required String serviceCode,
}) async {
  return _post('/tickets/create', {
    'userId': userId,
    'title': title,
    'description': description,
    'notes': notes,
    'priority': priority,
    'service': service,
    'serviceCode': serviceCode,
  });
}
  // ----------------------------------------------------------
  // PRIVATE: Generic POST handler
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeStatusCode = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body:    jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (includeStatusCode) {
        return {...data, 'statusCode': response.statusCode};
      }

      return data;
    } catch (_) {
      return {
        'success': false,
        'message': 'Connection error. Please check your network.',
      };
    }
  }
}