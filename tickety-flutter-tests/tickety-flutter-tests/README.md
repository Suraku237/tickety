# Tickety — Flutter Mobile Client Unit Tests

`flutter_test` + `mocktail`. Dart is natively object-oriented; the suite uses a
reusable `TestHarness` class, mock service classes (`extends Mock`), and model
factories.

## Layout
- `test/helpers/test_harness.dart` — shared setup, mock service classes, sample data.
- `test/models/ticket_test.dart` — model parsing, carry-over flag, UTC/ETA regression.
- `test/services/queue_service_test.dart` — swap-request visibility + ownership semantics.
- `test/widgets/ticket_card_test.dart` — widget render + carry-over badge.

## Run
```bash
# merge pubspec.test-deps.yaml into pubspec.yaml, then:
flutter pub get
flutter test
flutter test --coverage
```

## Adapt before running
Search for `ADAPT ME`. The model/widget files include local stand-in classes so
they compile standalone — delete each stand-in and import your real
`lib/` class once you wire them in. Update mock `implements` targets in
`test_harness.dart` to your real service interfaces.
