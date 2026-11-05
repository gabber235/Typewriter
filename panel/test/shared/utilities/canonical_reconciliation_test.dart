import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// No entries reconciled yet.
const List<({String id, int revision, String name})>? _none = null;

void main() {
  late List<FlutterErrorDetails> reported;

  setUp(() {
    reported = [];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
  });

  const first = (id: "first", revision: 2, name: "First");
  const second = (id: "second", revision: 1, name: "Second");

  test("a newer revision replaces the value with the same key", () {
    const renamed = (id: "first", revision: 3, name: "Renamed");

    final result = [first, second].reconcileBook(renamed);

    expect(result.values, [renamed, second]);
    expect(result.canonical, renamed);
    expect(reported, isEmpty);
  });

  test("an unknown key joins the collection, also when there is none", () {
    const third = (id: "third", revision: 1, name: "Third");

    expect([first].reconcileBook(third).values, [first, third]);
    expect(_none.reconcileBook(third).values, [third]);
    expect(_none.reconcileBook(third).canonical, third);
  });

  for (final (name, revision) in [("an older", 1), ("an equal", 2)]) {
    test("$name revision never replaces the canonical value", () {
      final incoming = (id: "first", revision: revision, name: "First");

      final result = [first, second].reconcileBook(incoming);

      expect(result.values, [first, second]);
      expect(result.canonical, first);
      expect(reported, isEmpty);
    });
  }

  test("an equal revision with a different value is reported and ignored", () {
    const diverged = (id: "first", revision: 2, name: "Diverged");

    final result = [first, second].reconcileBook(diverged);

    expect(result.values, [first, second]);
    expect(result.canonical, first);
    expect(
      reported.single.exception.toString(),
      contains("book first has different values at revision 2"),
    );
  });

  test("an older revision with a different value is ignored silently", () {
    const stale = (id: "first", revision: 1, name: "Stale");

    expect([first].reconcileBook(stale).canonical, first);
    expect(reported, isEmpty);
  });
}
