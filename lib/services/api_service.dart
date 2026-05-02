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
  // 🔐 TOKEN MANAGEMENT
  // =============================================================
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  // ✅ FIX: renamed to match HomePage usage
  void clearToken() {
    _token = null;
  }

  bool get isLoggedIn => _token != null;

  // =============================================================
  // 🧾 HEADERS (dynamic)
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
  // LOGIN (auto-save token)
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
    if (res['token'] != null && res['token'].toString().isNotEmpty) {
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
    return _post('/resend-otp', {
      'email': email,
    });
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
  // GET ALL TICKETS
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getTickets({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tickets/$userId'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      // fallback if backend returns array directly
      return {
        'success': true,
        'tickets': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch tickets',
      };
    }
  }

  // ----------------------------------------------------------
  // GET SINGLE TICKET
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getTicket({
    required String ticketId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ticket/$ticketId'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'ticket': data,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Failed to fetch ticket',
      };
    }
  }

  // ----------------------------------------------------------
  // PRIVATE: POST
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

      final decoded = jsonDecode(response.body);

      final data = decoded is Map<String, dynamic>
          ? decoded
          : {'data': decoded};

      if (includeStatusCode) {
        return {
          ...data,
          'statusCode': response.statusCode,
        };
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