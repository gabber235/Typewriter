import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("destination replacement releases both destinations once when cleanup ends the scope", () {
    final work = ScopedWorkSession();
    final driver = _Driver();
    final initial = _Destination();
    work.register(driver, destination: initial);
    initial.onDispose = work.dispose;
    final replacement = _Destination();
    expect(
      () =>
          work.getOrRegister(driver.id, _Driver.new, destination: replacement),
      throwsStateError,
    );
    expect(initial.disposals, 1);
    expect(replacement.disposals, 1);
    expect(driver.disposals, 1);
    work.dispose();
    expect(initial.disposals, 1);
    expect(replacement.disposals, 1);
  });

  test(
    "dirty drivers survive route lease release and clean drivers close once",
    () async {
      final work = ScopedWorkSession();
      final driver = _Driver();
      (work..register(driver)).lease(driver.id)
        ..release()
        ..release();
      expect(driver.disposals, 0);
      expect(work.state.entries.values.single.hasWork, isTrue);
      driver.settled();
      await Future<void>.delayed(Duration.zero);
      expect(driver.disposals, 1);
      expect(work.state.entries, isEmpty);
      work.dispose();
      expect(driver.disposals, 1);
    },
  );

  test("a clean driver is owned only by its route lease and releases without invisible retention", () {
    final work = ScopedWorkSession();
    final driver = _Driver(dirty: false);
    work.register(driver);
    final lease = work.lease(driver.id);
    expect(work.state.entries, isEmpty);
    expect(driver.disposals, 0);
    lease.release();
    expect(driver.disposals, 1);
    expect(work.state.entries, isEmpty);
    expect(() => work.lease(driver.id), throwsStateError);
    work.dispose();
    expect(driver.disposals, 1);
  });

  test(
    "scope disposal invalidates leases before cleanup callbacks reenter",
    () {
      final work = ScopedWorkSession();
      final driver = _Driver();
      var rejected = false;
      driver.onDispose = () {
        expect(() => work.lease(driver.id), throwsStateError);
        rejected = true;
        work.dispose();
      };
      final destination = _Destination();
      work.register(driver, destination: destination);
      final lease = work.lease(driver.id);
      work.dispose();
      lease.release();
      work.dispose();
      expect(rejected, isTrue);
      expect(driver.disposals, 1);
      expect(destination.disposals, 1);
    },
  );

  test("identical scopes in different domains never share a driver", () {
    final work = ScopedWorkSession();
    final graph = _Driver(domain: "authoring");
    final publication = _Driver(domain: "publication");
    work
      ..register(graph)
      ..register(publication);
    expect(work.state.entries, hasLength(2));
    work.dispose();
    expect(graph.disposals, 1);
    expect(publication.disposals, 1);
  });
}

final class _Driver extends ChangeNotifier implements WorkDriver {
  _Driver({this.domain = "fixture", this.dirty = true});
  final String domain;
  bool dirty;
  int disposals = 0;
  VoidCallback? onDispose;
  @override
  WorkDriverId get id => WorkDriverId(domain: domain, scope: "same realm");
  @override
  WorkDriverSnapshot get snapshot => WorkDriverSnapshot(
    entries: [
      if (dirty)
        WorkEntryState(
          id: WorkEntryId(driver: id, identity: "entry"),
          label: "Retained work",
          phase: "Local changes",
          retained: dirty,
          hasWork: dirty,
        ),
    ],
  );
  void settled() {
    dirty = false;
    notifyListeners();
  }

  @override
  Future<void> save(WorkEntryId entry) async => settled();
  @override
  bool discard(WorkEntryId entry) {
    settled();
    return true;
  }

  @override
  Future<void> retry(WorkEntryId entry) async => settled();
  @override
  void dispose() {
    disposals++;
    onDispose?.call();
    super.dispose();
  }
}

final class _Destination extends WorkDestination {
  int disposals = 0;
  VoidCallback? onDispose;
  @override
  bool get isCurrent => false;
  @override
  Future<void> open() async {}
  @override
  void dispose() {
    disposals++;
    onDispose?.call();
    super.dispose();
  }
}
