/// Widget test for the Tickety ticket card.
///
/// Verifies the card renders ticket details and shows the carry-over badge for
/// carried-over tickets.
///
/// ADAPT ME: replace the local `TicketCard` stand-in with an import of your
/// real widget: `import 'package:tickety/widgets/ticket_card.dart';`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// ----- Local stand-in widget so the test compiles standalone.
/// DELETE and import your real TicketCard. -----
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final Map<String, dynamic> ticket;

  @override
  Widget build(BuildContext context) {
    final carried = (ticket['carried_over'] as bool?) ?? false;
    return Card(
      child: Column(
        children: [
          Text(ticket['number'] as String),
          Text(ticket['status'] as String),
          if (carried) const Chip(label: Text('Carried over')),
        ],
      ),
    );
  }
}
/// ----- end stand-in -----

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('TicketCard widget', () {
    testWidgets('renders ticket number and status', (tester) async {
      final ticket = TestHarness.sampleTicket(number: 'C007', status: 'serving');
      await tester.pumpWidget(_wrap(TicketCard(ticket: ticket)));

      expect(find.text('C007'), findsOneWidget);
      expect(find.text('serving'), findsOneWidget);
    });

    testWidgets('shows the carry-over badge only when carried over',
        (tester) async {
      final normal = TestHarness.sampleTicket(carriedOver: false);
      await tester.pumpWidget(_wrap(TicketCard(ticket: normal)));
      expect(find.text('Carried over'), findsNothing);

      final carried = TestHarness.sampleTicket(carriedOver: true);
      await tester.pumpWidget(_wrap(TicketCard(ticket: carried)));
      expect(find.text('Carried over'), findsOneWidget);
    });
  });
}
