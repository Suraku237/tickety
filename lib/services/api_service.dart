import 'dart:convert';
import 'package:http/http.dart' as http;

// =============================================================
// API SERVICE  (Singleton)
// Responsibilities:
//   - Manage the single HTTP client instance
//   - Provide typed methods for every backend endpoint
//   - Send X-App-Source: mobile on every request so the backend
//     automatically assigns the 'client' role
//   - Persist and attach the auth token for protected routes
//   - Isolate all network logic from UI pages
// OOP Principle: Singleton, Encapsulation, Abstraction
// =============================================================
class ApiService {
  // --- Singleton ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- Configuration ---
  static const String _baseUrl = 'http://192.168.1.100:5000/api';

  // Auth token set after a successful login — sent on protected calls
  String? _token;
  void setToken(String token) => _token = token;
  void clearToken()           => _token = null;

  // Base headers (no auth)
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'X-App-Source': 'mobile',
  };

  // Headers that include the Bearer token when available
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
  // Stores the returned token automatically if present.
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
  // QUEUE JOIN — PREVIEW (GET before confirming)
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> previewQueue({
    required String joinToken,
  }) =>
      _get('/join/$joinToken');

  // ----------------------------------------------------------
  // QUEUE JOIN — ISSUE TICKET (POST after user confirms)
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> joinQueue({
    required String joinToken,
    String? customerIdentifier,
  }) =>
      _post(
        '/join/$joinToken',
        {'customer_identifier': customerIdentifier ?? ''},
        useAuth: true,
      );

  // ----------------------------------------------------------
  // TICKETS — GET ALL (for the current user)
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getTickets({
    required String userId,
    String? email,
    String? status,
    String? priority,
  }) {
    final params = <String, String>{};
    if (email    != null) params['user_email'] = email;
    else                  params['user_id']    = userId;
    if (status   != null) params['status']     = status;
    if (priority != null) params['priority']   = priority;
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
  // TICKETS — CHECK IF CALLED (position=0, status=active)
  // GET /api/tickets/<ticket_id>/called
  // Polls the backend to see if this ticket has been called to
  // the counter. Returns { called, counter, deleted }.
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> checkTicketCalled({
    required String ticketId,
  }) =>
      _get('/tickets/$ticketId/called', useAuth: true);

  // ----------------------------------------------------------
  // TICKETS — DELETE (leave queue)
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> deleteTicket({
    required String ticketId,
    required String userId,
  }) =>
      _delete('/tickets/$ticketId', {'user_id': userId}, useAuth: true);

  // ----------------------------------------------------------
  // ACCOUNT — CHANGE PASSWORD
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) =>
      _post('/change-password', {
        'user_id':          userId,
        'current_password': currentPassword,
        'new_password':     newPassword,
      }, useAuth: true);

  // ----------------------------------------------------------
  // ACCOUNT — DELETE
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> deleteAccount({
    required String userId,
  }) =>
      _post('/delete-account', {'user_id': userId}, useAuth: true);

  // ----------------------------------------------------------
  // SERVICES — BROWSE (public: visited + non-visited + wait time)
  // GET /api/services/browse?q=<search>&user_email=<email>
  // Returns each service with people_waiting, avg_wait_minutes,
  // num_queues and a `visited` flag.
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> browseServices({
    String? query,
    String? userEmail,
  }) {
    final params = <String, String>{};
    if (query     != null && query.isNotEmpty)     params['q']          = query;
    if (userEmail != null && userEmail.isNotEmpty) params['user_email'] = userEmail;
    return _get('/services/browse', queryParams: params, useAuth: true);
  }

  // ==========================================================
  // PROFILE — EMAIL CHANGE (3-step, mirrors the web flow)
  // ==========================================================

  // Step 1: send OTP to the OLD email to confirm ownership.
  Future<Map<String, dynamic>> initiateEmailChange({
    required String userId,
    required String newEmail,
  }) =>
      _post('/profile/email/initiate',
          {'user_id': userId, 'new_email': newEmail}, useAuth: true);

  // Step 2: verify the OLD-email OTP (backend then sends OTP to NEW email).
  Future<Map<String, dynamic>> confirmOldEmail({
    required String userId,
    required String code,
  }) =>
      _post('/profile/email/confirm-old',
          {'user_id': userId, 'code': code}, useAuth: true);

  // Step 3: verify the NEW-email OTP and apply the change.
  Future<Map<String, dynamic>> confirmNewEmail({
    required String userId,
    required String code,
  }) =>
      _post('/profile/email/confirm-new',
          {'user_id': userId, 'code': code}, useAuth: true);

  // PROFILE — UPDATE USERNAME
  Future<Map<String, dynamic>> updateUsername({
    required String userId,
    required String username,
  }) =>
      _patch('/profile/username',
          {'user_id': userId, 'username': username}, useAuth: true);

  // ----------------------------------------------------------
  // SCHEDULE — GET CURRENT STATUS FOR A SERVICE
  // GET /api/schedule/status?service_id=<id>
  // Returns: is_open, opening_time, closing_time, avg_duration
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getScheduleStatus({
    required String serviceId,
  }) =>
      _get('/schedule/status',
          queryParams: {'service_id': serviceId}, useAuth: true);

  // ==========================================================
  // SWAP ENDPOINTS
  // ==========================================================

  // ----------------------------------------------------------
  // SWAP — LIST AVAILABLE TICKETS TO SWAP WITH
  // GET /api/swap/available?requester_ticket_id=<id>
  //
  // Returns all tickets in the same service that the requester
  // can propose a swap to, with a flag for any already-pending
  // requests.
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getSwappableTickets({
    required String requesterTicketId,
  }) =>
      _get('/swap/available',
          queryParams: {'requester_ticket_id': requesterTicketId},
          useAuth: true);

  // ----------------------------------------------------------
  // SWAP — SEND A REQUEST
  // POST /api/swap/request
  // Body: { requester_ticket_id, target_ticket_id }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> requestSwap({
    required String requesterTicketId,
    required String targetTicketId,
  }) =>
      _post('/swap/request', {
        'requester_ticket_id': requesterTicketId,
        'target_ticket_id':    targetTicketId,
      }, useAuth: true);

  // ----------------------------------------------------------
  // SWAP — GET INCOMING REQUESTS (for target)
  // GET /api/swap/incoming?target_ticket_id=<id>
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getIncomingSwapRequests({
    required String targetTicketId,
  }) =>
      _get('/swap/incoming',
          queryParams: {'target_ticket_id': targetTicketId},
          useAuth: true);

  // ----------------------------------------------------------
  // SWAP — GET OUTGOING REQUESTS (for requester)
  // GET /api/swap/outgoing?requester_ticket_id=<id>
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getOutgoingSwapRequests({
    required String requesterTicketId,
  }) =>
      _get('/swap/outgoing',
          queryParams: {'requester_ticket_id': requesterTicketId},
          useAuth: true);

  // ----------------------------------------------------------
  // SWAP — RESPOND (accept or reject)
  // POST /api/swap/<swap_id>/respond
  // Body: { action: 'accept' | 'reject' }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> respondToSwap({
    required String swapId,
    required String action,   // 'accept' or 'reject'
  }) =>
      _post('/swap/$swapId/respond', {'action': action}, useAuth: true);

  // ----------------------------------------------------------
  // SWAP — CANCEL (by requester)
  // DELETE /api/swap/<swap_id>
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> cancelSwap({
    required String swapId,
  }) =>
      _delete('/swap/$swapId', {}, useAuth: true);

  // ==========================================================
  // PRIVATE: HTTP helpers
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
      final req = http.Request('DELETE', Uri.parse('$_baseUrl$endpoint'));
      req.headers.addAll(useAuth ? _authHeaders : _baseHeaders);
      req.body = jsonEncode(body);
      final streamed = await req.send();
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