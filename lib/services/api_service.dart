import 'dart:convert';
import 'package:http/http.dart' as http;

// =============================================================
// API SERVICE  (Singleton)
// =============================================================
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'http://109.199.120.38:5000/api';

  String? _token;
  void setToken(String token) => _token = token;
  void clearToken()           => _token = null;

  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'X-App-Source': 'mobile',
  };

  Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ----------------------------------------------------------
  // AUTH — REGISTER
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) =>
      _post('/register', {
        'username': username,
        'email':    email,
        'password': password,
      });

  // ----------------------------------------------------------
  // AUTH — LOGIN
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      '/login',
      {'email': email, 'password': password},
      includeStatusCode: true,
    );
    if (data['success'] == true && data['token'] != null) {
      _token = data['token'] as String;
    }
    return data;
  }

  // ----------------------------------------------------------
  // AUTH — VERIFY EMAIL
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) =>
      _post('/verify-email', {'email': email, 'code': code});

  // ----------------------------------------------------------
  // AUTH — RESEND OTP
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> resendOtp({required String email}) =>
      _post('/resend-otp', {'email': email});

  // ----------------------------------------------------------
  // AUTH — FORGOT PASSWORD  (request reset OTP)
  // POST /forgot-password  { email }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) =>
      _post('/forgot-password', {'email': email});

  // ----------------------------------------------------------
  // AUTH — RESET PASSWORD  (submit OTP + new password)
  // POST /reset-password  { email, code, new_password }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _post('/reset-password', {
        'email':        email,
        'code':         code,
        'new_password': newPassword,
      });

  // ----------------------------------------------------------
  // TICKETS — CREATE
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> createTicket({
    required String userId,
    required String title,
    required String description,
    required String notes,
    required String priority,
    required String service,
    required String serviceCode,
  }) =>
      _post(
        '/tickets',
        {
          'user_id':      userId,
          'title':        title,
          'description':  description,
          'notes':        notes,
          'priority':     priority,
          'service':      service,
          'service_code': serviceCode,
        },
        useAuth: true,
      );

  // ----------------------------------------------------------
  // TICKETS — GET ALL
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getTickets({
    required String userId,
    String? status,
    String? priority,
  }) {
    final params = <String, String>{'user_id': userId};
    if (status   != null) params['status']   = status;
    if (priority != null) params['priority'] = priority;
    return _get('/tickets', queryParams: params, useAuth: true);
  }

  // ----------------------------------------------------------
  // TICKETS — GET ONE
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getTicket({
    required String ticketId,
    required String userId,
  }) =>
      _get('/tickets/$ticketId',
          queryParams: {'user_id': userId}, useAuth: true);

  // ----------------------------------------------------------
  // TICKETS — UPDATE STATUS
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> updateTicketStatus({
    required String ticketId,
    required String userId,
    required String status,
  }) =>
      _patch(
        '/tickets/$ticketId',
        {'user_id': userId, 'status': status},
        useAuth: true,
      );

  // ----------------------------------------------------------
  // TICKETS — UPDATE FULL
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> updateTicket({
    required String ticketId,
    required String userId,
    String? title,
    String? description,
    String? notes,
    String? priority,
    String? status,
    String? assignedTo,   // ← for ticket swap
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (title       != null) body['title']       = title;
    if (description != null) body['description'] = description;
    if (notes       != null) body['notes']       = notes;
    if (priority    != null) body['priority']    = priority;
    if (status      != null) body['status']      = status;
    if (assignedTo  != null) body['assigned_to'] = assignedTo;
    return _patch('/tickets/$ticketId', body, useAuth: true);
  }

  // ----------------------------------------------------------
  // TICKETS — DELETE
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> deleteTicket({
    required String ticketId,
    required String userId,
  }) =>
      _delete('/tickets/$ticketId', {'user_id': userId}, useAuth: true);

  // ==========================================================
  // PRIVATE HTTP helpers
  // ==========================================================

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeStatusCode = false,
    bool useAuth           = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: useAuth ? _authHeaders : _baseHeaders,
        body:    jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return includeStatusCode
          ? {...data, 'statusCode': response.statusCode}
          : data;
    } catch (_) {
      return _networkError();
    }
  }

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool useAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: useAuth ? _authHeaders : _baseHeaders,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return _networkError();
    }
  }

  Future<Map<String, dynamic>> _patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool useAuth = false,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: useAuth ? _authHeaders : _baseHeaders,
        body:    jsonEncode(body),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return _networkError();
    }
  }

  Future<Map<String, dynamic>> _delete(
    String endpoint,
    Map<String, dynamic> body, {
    bool useAuth = false,
  }) async {
    try {
      final request = http.Request(
          'DELETE', Uri.parse('$_baseUrl$endpoint'));
      request.headers.addAll(useAuth ? _authHeaders : _baseHeaders);
      request.body = jsonEncode(body);
      final streamed = await request.send();
      final resp     = await http.Response.fromStream(streamed);
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return _networkError();
    }
  }

  Map<String, dynamic> _networkError() => {
    'success': false,
    'message': 'Connection error. Please check your network.',
  };
}
