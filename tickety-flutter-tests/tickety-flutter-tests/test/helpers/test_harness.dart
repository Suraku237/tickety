/// Shared test helpers for the Tickety Flutter client.
///
/// Object-Oriented design notes
/// ----------------------------
/// - [TestHarness] encapsulates common setup (mock wiring, sample data) behind
///   one reusable object instead of repeating boilerplate in every test.
/// - Mock services are real classes (`extends Mock implements <Service>`),
///   which is idiomatic Dart OOP and enables dependency injection.
///
/// ADAPT ME: the `implements` targets and model constructors must match your
/// real `lib/` classes (e.g. `ApiService`, `QueueService`, `Ticket`).
library;

import 'package:mocktail/mocktail.dart';

// ADAPT ME: import your real service/model interfaces.
// import 'package:tickety/services/api_service.dart';
// import 'package:tickety/services/queue_service.dart';

/// Mock of the network/API service. Replace `Object` with your real type:
/// `class MockApiService extends Mock implements ApiService {}`
class MockApiService extends Mock {}

/// Mock of the queue/ticket service.
class MockQueueService extends Mock {}

/// Bundles the collaborators a widget/service test needs, constructed once.
class TestHarness {
  TestHarness()
      : api = MockApiService(),
        queues = MockQueueService();

  final MockApiService api;
  final MockQueueService queues;

  /// Factory for a plausible ticket map (swap for your real model object).
  static Map<String, dynamic> sampleTicket({
    int id = 1,
    String number = 'A001',
    String status = 'waiting',
    bool carriedOver = false,
  }) {
    return <String, dynamic>{
      'id': id,
      'number': number,
      'status': status,
      'carried_over': carriedOver,
    };
  }
}
