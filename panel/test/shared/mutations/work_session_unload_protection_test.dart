import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("binding updates protection and disposes its adapter", (
    tester,
  ) async {
    final adapter = RecordingUnloadProtection();
    await tester.showComponent(
      WorkSessionUnloadBinding(
        protected: false,
        protection: adapter,
        child: const SizedBox(),
      ),
    );

    await tester.showComponent(
      WorkSessionUnloadBinding(
        protected: true,
        protection: adapter,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    expect(adapter.values, [false, true]);
    expect(adapter.disposed, isTrue);
  });

  testWidgets("replacing an adapter disposes the previous listener", (
    tester,
  ) async {
    final first = RecordingUnloadProtection();
    final second = RecordingUnloadProtection();
    await tester.showComponent(
      WorkSessionUnloadBinding(
        protected: true,
        protection: first,
        child: const SizedBox(),
      ),
    );

    await tester.showComponent(
      WorkSessionUnloadBinding(
        protected: true,
        protection: second,
        child: const SizedBox(),
      ),
    );

    expect(first.disposed, isTrue);
    expect(second.values, [true]);
  });
}
