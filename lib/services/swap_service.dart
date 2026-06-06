import 'api_service.dart';

// =============================================================
// SWAP REQUEST MODEL  (client-side DTO)
// =============================================================
class SwapRequestItem {
  final String  swapId;
  final String  serviceId;
  final String  requesterTicketId;
  final String  targetTicketId;
  final String  status;           // pending | accepted | rejected | expired
  final String  createdAt;
  final String? respondedAt;

  // Extra fields populated by the list endpoints
  final String? counterpartCode;     // the other ticket's code
  final int?    counterpartPosition; // the other ticket's position

  const SwapRequestItem({
    required this.swapId,
    required this.serviceId,
    required this.requesterTicketId,
    required this.targetTicketId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.counterpartCode,
    this.counterpartPosition,
  });

  factory SwapRequestItem.fromMap(Map<String, dynamic> m, {
    bool isIncoming = false,
  }) {
    return SwapRequestItem(
      swapId:              m['swap_id']?.toString()    ?? '',
      serviceId:           m['service_id']?.toString() ?? '',
      requesterTicketId:   m['requester_ticket_id']?.toString() ?? '',
      targetTicketId:      m['target_ticket_id']?.toString()    ?? '',
      status:              m['status']?.toString()     ?? 'pending',
      createdAt:           m['created_at']?.toString() ?? '',
      respondedAt:         m['responded_at']?.toString(),
      counterpartCode: isIncoming
          ? m['requester_code']?.toString()
          : m['target_code']?.toString(),
      counterpartPosition: isIncoming
          ? (m['requester_position'] as num?)?.toInt()
          : (m['target_position']    as num?)?.toInt(),
    );
  }

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

// =============================================================
// SWAPPABLE TICKET MODEL  (ticket visible in the picker)
// =============================================================
class SwappableTicket {
  final String ticketId;
  final String code;
  final String queueId;
  final String status;
  final int?   position;
  final bool   hasPendingRequest;

  const SwappableTicket({
    required this.ticketId,
    required this.code,
    required this.queueId,
    required this.status,
    this.position,
    this.hasPendingRequest = false,
  });

  factory SwappableTicket.fromMap(Map<String, dynamic> m) {
    return SwappableTicket(
      ticketId:          m['ticket_id']?.toString()  ?? '',
      code:              m['code']?.toString()        ?? '',
      queueId:           m['queue_id']?.toString()   ?? '',
      status:            m['status']?.toString()     ?? '',
      position:          (m['position'] as num?)?.toInt(),
      hasPendingRequest: m['has_pending_request'] == true,
    );
  }
}

// =============================================================
// SWAP SERVICE  (Singleton)
// Responsibilities:
//   - Wrap all swap API calls with typed return values
//   - Keep business logic out of the UI layer
// OOP Principle: Singleton, Single Responsibility, Abstraction
// =============================================================
class SwapService {
  static final SwapService _instance = SwapService._internal();
  factory SwapService() => _instance;
  SwapService._internal();

  final _api = ApiService();

  // ----------------------------------------------------------
  // Load available tickets to swap with
  // ----------------------------------------------------------
  Future<({bool success, String? error, List<SwappableTicket> tickets})>
      loadAvailable({required String requesterTicketId}) async {
    final data = await _api.getSwappableTickets(
        requesterTicketId: requesterTicketId);
    if (data['success'] != true) {
      return (
        success: false,
        error:   data['message']?.toString() ?? 'Failed to load tickets',
        tickets: <SwappableTicket>[],
      );
    }
    final raw = (data['available_tickets'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return (
      success: true,
      error:   null,
      tickets: raw.map(SwappableTicket.fromMap).toList(),
    );
  }

  // ----------------------------------------------------------
  // Send a swap request
  // ----------------------------------------------------------
  Future<({bool success, String message})> sendRequest({
    required String requesterTicketId,
    required String targetTicketId,
  }) async {
    final data = await _api.requestSwap(
      requesterTicketId: requesterTicketId,
      targetTicketId:    targetTicketId,
    );
    return (
      success: data['success'] == true,
      message: data['message']?.toString() ?? 'Unknown error',
    );
  }

  // ----------------------------------------------------------
  // Load incoming swap requests for a ticket
  // ----------------------------------------------------------
  Future<({bool success, String? error, List<SwapRequestItem> items})>
      loadIncoming({required String targetTicketId}) async {
    final data = await _api.getIncomingSwapRequests(
        targetTicketId: targetTicketId);
    if (data['success'] != true) {
      return (
        success: false,
        error:   data['message']?.toString(),
        items:   <SwapRequestItem>[],
      );
    }
    final raw = (data['incoming'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return (
      success: true,
      error:   null,
      items:   raw
          .map((m) => SwapRequestItem.fromMap(m, isIncoming: true))
          .toList(),
    );
  }

  // ----------------------------------------------------------
  // Load outgoing swap requests for a ticket
  // ----------------------------------------------------------
  Future<({bool success, String? error, List<SwapRequestItem> items})>
      loadOutgoing({required String requesterTicketId}) async {
    final data = await _api.getOutgoingSwapRequests(
        requesterTicketId: requesterTicketId);
    if (data['success'] != true) {
      return (
        success: false,
        error:   data['message']?.toString(),
        items:   <SwapRequestItem>[],
      );
    }
    final raw = (data['outgoing'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return (
      success: true,
      error:   null,
      items:   raw.map((m) => SwapRequestItem.fromMap(m)).toList(),
    );
  }

  // ----------------------------------------------------------
  // Accept a swap request
  // ----------------------------------------------------------
  Future<({bool success, String message})> accept(String swapId) async {
    final data = await _api.respondToSwap(swapId: swapId, action: 'accept');
    return (
      success: data['success'] == true,
      message: data['message']?.toString() ?? 'Unknown error',
    );
  }

  // ----------------------------------------------------------
  // Reject a swap request
  // ----------------------------------------------------------
  Future<({bool success, String message})> reject(String swapId) async {
    final data = await _api.respondToSwap(swapId: swapId, action: 'reject');
    return (
      success: data['success'] == true,
      message: data['message']?.toString() ?? 'Unknown error',
    );
  }

  // ----------------------------------------------------------
  // Cancel a swap request (by requester)
  // ----------------------------------------------------------
  Future<({bool success, String message})> cancel(String swapId) async {
    final data = await _api.cancelSwap(swapId: swapId);
    return (
      success: data['success'] == true,
      message: data['message']?.toString() ?? 'Unknown error',
    );
  }
}