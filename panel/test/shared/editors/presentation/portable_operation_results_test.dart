import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const key = PortableOperationKey.status();
  const applied = PortablePresentationWriteApplied();

  test(
    "only the current applied request invokes its applied callback",
    () async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final first = Completer<PortablePresentationWriteResult>();
      final callbacks = <String>[];
      final pending = operations.run(
        key: key,
        operation: () => first.future,
        onApplied: () => callbacks.add("first"),
      );
      await operations.run(
        key: key,
        operation: () => applied,
        onApplied: () => callbacks.add("second"),
      );
      first.complete(applied);
      await pending;
      expect(callbacks, ["second"]);
    },
  );

  test(
    "rejected and retired requests never invoke applied callbacks",
    () async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      var callbacks = 0;
      await operations.run(
        key: key,
        operation: () => const PortablePresentationWriteRejected([]),
        onApplied: () => callbacks++,
      );
      final response = Completer<PortablePresentationWriteResult>();
      final pending = operations.run(
        key: key,
        operation: () => response.future,
        onApplied: () => callbacks++,
      );
      operations.retirePending();
      response.complete(applied);
      await pending;
      expect(callbacks, 0);
    },
  );

  test(
    "disposing during a pending request prevents its applied callback",
    () async {
      final operations = PortableOperationResults();
      final response = Completer<PortablePresentationWriteResult>();
      var callbacks = 0;
      final pending = operations.run(
        key: key,
        operation: () => response.future,
        onApplied: () => callbacks++,
      );
      operations.dispose();
      response.complete(applied);
      await pending;
      expect(callbacks, 0);
    },
  );

  test(
    "a newer request during settlement prevents the old applied callback",
    () async {
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final replacement = Completer<PortablePresentationWriteResult>();
      final callbacks = <String>[];
      Future<void>? newer;
      var replaced = false;
      operations.addListener(() {
        if (!replaced && operations.value.outcomes.isEmpty) {
          replaced = true;
          newer = operations.run(
            key: key,
            operation: () => replacement.future,
            onApplied: () => callbacks.add("newer"),
          );
        }
      });
      await operations.run(
        key: key,
        operation: () => applied,
        onApplied: () => callbacks.add("original"),
      );
      expect(callbacks, isEmpty);
      replacement.complete(applied);
      await newer;
      expect(callbacks, ["newer"]);
    },
  );
}
