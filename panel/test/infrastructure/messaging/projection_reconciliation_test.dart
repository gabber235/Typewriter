import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("an event at or before the snapshot is a duplicate and changes "
      "nothing", () {
    final collection = (SequencedCollection<int>()
      ..snapshot = const SequencedSnapshot(sequence: 3, value: 30));

    for (final sequence in [2, 3]) {
      expect(
        collection.apply(sequence: sequence, reduce: (_) => 99),
        SequencedEventResult.duplicate,
      );
    }
    expect(collection.snapshot?.sequence, 3);
    expect(collection.value, 30);
  });

  test("an event that skips ahead is a gap and changes nothing", () {
    final collection = (SequencedCollection<int>()
      ..snapshot = const SequencedSnapshot(sequence: 3, value: 30));

    expect(
      collection.apply(sequence: 5, reduce: (_) => 50),
      SequencedEventResult.gap,
    );
    expect(collection.snapshot?.sequence, 3);
    expect(collection.value, 30);
  });

  test("the next event applies against the current value", () {
    final collection = (SequencedCollection<int>()
      ..snapshot = const SequencedSnapshot(sequence: 3, value: 30));

    expect(
      collection.apply(sequence: 4, reduce: (current) => current + 1),
      SequencedEventResult.applied,
    );
    expect(collection.snapshot?.sequence, 4);
    expect(collection.value, 31);
  });
}
