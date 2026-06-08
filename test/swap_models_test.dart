// =============================================================
// Unit tests for the swap DTOs in lib/services/swap_service.dart:
//   - SwapRequestItem.fromMap (incoming vs outgoing counterpart mapping)
//   - SwappableTicket.fromMap (type coercion, defaults)
//   - status predicates
//
// These are pure value objects, so no mocking or binding is needed.
//
// >>> SET PACKAGE NAME <<<
// Replace `tickety` below with the `name:` field from your pubspec.yaml.
// =============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:tickety/services/swap_service.dart';

void main() {
  group('SwapRequestItem.fromMap', () {
    final base = {
      'swap_id': 7,
      'service_id': 3,
      'requester_ticket_id': 11,
      'target_ticket_id': 22,
      'status': 'pending',
      'created_at': '2024-01-01T09:00:00',
      'requester_code': 'A011',
      'requester_position': 4,
      'target_code': 'B022',
      'target_position': 9,
    };

    test('coerces numeric ids to strings', () {
      final item = SwapRequestItem.fromMap(base);
      expect(item.swapId, '7');
      expect(item.requesterTicketId, '11');
      expect(item.targetTicketId, '22');
    });

    test('outgoing (default) maps the target as counterpart', () {
      final item = SwapRequestItem.fromMap(base);
      expect(item.counterpartCode, 'B022');
      expect(item.counterpartPosition, 9);
    });

    test('incoming maps the requester as counterpart', () {
      final item = SwapRequestItem.fromMap(base, isIncoming: true);
      expect(item.counterpartCode, 'A011');
      expect(item.counterpartPosition, 4);
    });

    test('defaults status to pending and respondedAt to null', () {
      final item = SwapRequestItem.fromMap({'swap_id': 1});
      expect(item.status, 'pending');
      expect(item.respondedAt, isNull);
      expect(item.serviceId, '');
    });

    test('status predicates', () {
      expect(SwapRequestItem.fromMap({'status': 'pending'}).isPending, isTrue);
      expect(SwapRequestItem.fromMap({'status': 'accepted'}).isAccepted, isTrue);
      expect(SwapRequestItem.fromMap({'status': 'rejected'}).isRejected, isTrue);
      expect(SwapRequestItem.fromMap({'status': 'accepted'}).isPending, isFalse);
    });
  });

  group('SwappableTicket.fromMap', () {
    test('maps fields and coerces position to int', () {
      final t = SwappableTicket.fromMap({
        'ticket_id': 5,
        'code': 'C005',
        'queue_id': 2,
        'status': 'pending',
        'position': 3,
        'has_pending_request': true,
      });
      expect(t.ticketId, '5');
      expect(t.code, 'C005');
      expect(t.queueId, '2');
      expect(t.position, 3);
      expect(t.hasPendingRequest, isTrue);
    });

    test('applies safe defaults for missing fields', () {
      final t = SwappableTicket.fromMap({});
      expect(t.ticketId, '');
      expect(t.code, '');
      expect(t.position, isNull);
      expect(t.hasPendingRequest, isFalse);
    });

    test('has_pending_request is only true for an exact boolean true', () {
      expect(SwappableTicket.fromMap({'has_pending_request': 'true'})
          .hasPendingRequest, isFalse);
      expect(SwappableTicket.fromMap({'has_pending_request': 1})
          .hasPendingRequest, isFalse);
    });
  });
}
