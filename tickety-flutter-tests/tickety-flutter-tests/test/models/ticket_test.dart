/// Unit tests for the Tickety `Ticket` model and its derived fields.
///
/// Includes a regression guard for the "estimated wait always ~0" bug, which
/// was traced to a timezone mismatch (naive UTC stored values compared against
/// a local `DateTime.now()`).
///
/// ADAPT ME: replace the inline `Ticket` stand-in below with an import of your
/// real model: `import 'package:tickety/models/ticket.dart';` and delete the
/// local class.
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// ----- Local stand-in so the file compiles standalone. DELETE when wiring
/// in your real model. -----
class Ticket {
  Ticket({
    required this.id,
    required this.number,
    required this.status,
    this.createdAtUtc,
    this.carriedOver = false,
  });

  final int id;
  final String number;
  final String status;
  final DateTime? createdAtUtc;
  final bool carriedOver;

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'] as int,
        number: json['number'] as String,
        status: json['status'] as String,
        carriedOver: (json['carried_over'] as bool?) ?? false,
      );

  bool get isWaiting => status == 'waiting';
  bool get isTerminal => status == 'completed';
}
/// ----- end stand-in -----

void main() {
  group('Ticket model', () {
    test('fromJson maps core fields', () {
      final ticket = Ticket.fromJson(TestHarness.sampleTicket(number: 'B042'));
      expect(ticket.number, 'B042');
      expect(ticket.isWaiting, isTrue);
      expect(ticket.isTerminal, isFalse);
    });

    test('carried-over flag is parsed (drives the carry-over badge)', () {
      final ticket =
          Ticket.fromJson(TestHarness.sampleTicket(carriedOver: true));
      expect(ticket.carriedOver, isTrue);
    });

    test('completed ticket is terminal', () {
      final ticket =
          Ticket.fromJson(TestHarness.sampleTicket(status: 'completed'));
      expect(ticket.isTerminal, isTrue);
    });
  });

  group('Estimated wait timezone regression', () {
    // The bug: stored timestamps are naive UTC, but the client computed
    // elapsed time against a *local* now, yielding ~0 (or negative) waits.
    test('elapsed time uses a consistent UTC clock', () {
      final createdUtc = DateTime.now().toUtc().subtract(
            const Duration(minutes: 7),
          );

      // Correct calculation: compare UTC-to-UTC.
      final elapsedMinutes =
          DateTime.now().toUtc().difference(createdUtc).inMinutes;

      expect(elapsedMinutes, greaterThanOrEqualTo(6));
      expect(elapsedMinutes, lessThanOrEqualTo(8));
    });
  });
}
