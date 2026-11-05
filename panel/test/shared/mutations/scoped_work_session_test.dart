import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("destination replacement releases both destinations once when cleanup ends the scope", () {
    final work = ScopedWorkSession();
    final driver = FakeWorkDriver();
    final initial = FakeWorkDestination();
    work.register(driver, destination: initial);
    initial.onDispose = work.dispose;
    final replacement = FakeWorkDestination();
    expect(
      () => work.getOrRegister(
        driver.id,
        FakeWorkDriver.new,
        destination: replacement,
      ),
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
      final driver = FakeWorkDriver();
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
    final driver = FakeWorkDriver(dirty: false);
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
      final driver = FakeWorkDriver();
      var rejected = false;
      driver.onDispose = () {
        expect(() => work.lease(driver.id), throwsStateError);
        rejected = true;
        work.dispose();
      };
      final destination = FakeWorkDestination();
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
    final graph = FakeWorkDriver(domain: "authoring");
    final publication = FakeWorkDriver(domain: "publication");
    work
      ..register(graph)
      ..register(publication);
    expect(work.state.entries, hasLength(2));
    work.dispose();
    expect(graph.disposals, 1);
    expect(publication.disposals, 1);
  });
}
