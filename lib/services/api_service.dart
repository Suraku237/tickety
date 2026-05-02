import 'dart:convert';
import 'package:http/http.dart' as http;

// =============================================================
// API SERVICE (Singleton)
// =============================================================
class ApiService {
  // --- Singleton setup ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- Configuration ---
  static const String _baseUrl = 'http://109.199.120.38:5000/api';

  // =============================================================
  // 🔐 TOKEN MANAGEMENT (ADDED)
  // =============================================================
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clear() {
    _token = null;
  }

  // =============================================================
  // 🧾 HEADERS (UPDATED → dynamic for auth)
  // =============================================================
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'X-App-Source': 'mobile',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

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
      'email': email,
      'password': password,
    });
  }

  // ----------------------------------------------------------
  // LOGIN (UPDATED → saves token)
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _post(
      '/login',
      {
        'email': email,
        'password': password,
      },
      includeStatusCode: true,
    );

    // ✅ Save token automatically
    if (res['token'] != null) {
      setToken(res['token']);
    }

    return res;
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
      'code': code,
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
  // CREATE TICKET (YOUR FEATURE)
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

  // =============================================================
  // OPTIONAL (if you use later — safe to keep)
  // =============================================================

  // Get all tickets for a user
  Future<Map<String, dynamic>> getTickets(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tickets/$userId'),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (_) {
      return {
        'success': false,
        'message': 'Failed to fetch tickets',
      };
    }
  }

  // Get single ticket
  Future<Map<String, dynamic>> getTicket(String ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ticket/$ticketId'),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (_) {
      return {
        'success': false,
        'message': 'Failed to fetch ticket',
      };
    }
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
        body: jsonEncode(body),
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