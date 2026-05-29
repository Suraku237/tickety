// =============================================================
// TICKET MODEL  (Immutable DTO)
// Shared across TicketListPage, TicketDetailPage, Dashboard.
// Centralises all field names so a backend rename is one edit.
// =============================================================
class Ticket {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String notes;
  final String priority;   // urgent | high | medium | low
  final String status;     // open | pending | closed
  final String service;
  final String serviceCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional field for ticket swapping — who the ticket is currently held by
  final String? assignedTo;
  final String? assignedUsername;

  const Ticket({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.notes,
    required this.priority,
    required this.status,
    required this.service,
    required this.serviceCode,
    this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.assignedUsername,
  });

  factory Ticket.fromMap(Map<String, dynamic> data) {
    return Ticket(
      id:               data['id']?.toString()            ?? data['_id']?.toString() ?? '',
      userId:           data['user_id']?.toString()       ?? '',
      title:            data['title']     as String?      ?? 'Untitled',
      description:      data['description'] as String?    ?? '',
      notes:            data['notes']     as String?      ?? '',
      priority:         data['priority']  as String?      ?? 'low',
      status:           data['status']    as String?      ?? 'open',
      service:          data['service']   as String?      ?? '',
      serviceCode:      data['service_code'] as String?   ?? '',
      createdAt:        _parseDate(data['created_at']),
      updatedAt:        _parseDate(data['updated_at']),
      assignedTo:       data['assigned_to']?.toString(),
      assignedUsername: data['assigned_username'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try { return DateTime.parse(raw.toString()); } catch (_) { return null; }
  }

  Ticket copyWith({
    String? status,
    String? priority,
    String? title,
    String? description,
    String? notes,
    String? assignedTo,
    String? assignedUsername,
  }) {
    return Ticket(
      id:               id,
      userId:           userId,
      title:            title            ?? this.title,
      description:      description      ?? this.description,
      notes:            notes            ?? this.notes,
      priority:         priority         ?? this.priority,
      status:           status           ?? this.status,
      service:          service,
      serviceCode:      serviceCode,
      createdAt:        createdAt,
      updatedAt:        updatedAt,
      assignedTo:       assignedTo       ?? this.assignedTo,
      assignedUsername: assignedUsername ?? this.assignedUsername,
    );
  }

  bool get isOpen    => status == 'open';
  bool get isPending => status == 'pending';
  bool get isClosed  => status == 'closed';
  bool get isUrgent  => priority == 'urgent';
}
