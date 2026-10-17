import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final class _RecordingProtection implements WorkSessionUnloadProtection {
  final List<bool> values = [];
  bool disposed = false;

  @override
  bool get protected => values.lastOrNull ?? false;

  @override
  set protected(bool value) => values.add(value);

  @override
  void dispose() => disposed = true;
}

void main() {
  testWidgets("binding updates protection and disposes its adapter", (
    tester,
  ) async {
    final protection = _RecordingProtection();

    await tester.pumpWidget(
      WorkSessionUnloadBinding(
        protected: false,
        protection: protection,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(
      WorkSessionUnloadBinding(
        protected: true,
        protection: protection,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    expect(protection.values, [false, true]);
    expect(protection.disposed, isTrue);
  });

  testWidgets("replacing an adapter disposes the previous listener", (
    tester,
  ) async {
    final first = _RecordingProtection();
    final second = _RecordingProtection();

    await tester.pumpWidget(
      WorkSessionUnloadBinding(
        protected: true,
        protection: first,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(
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
