import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/provider_test_utils.dart";

part "tag_authoring_consistency_test_support.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "applied color save never installs stale tag content at the new revision",
    () async {
      final harness = await _Harness.create();
      final source = await harness.openEditor();
      final revisionTwo = Completer<void>();
      final workSubscription = harness.container.listen(localWorkProvider, (
        _,
        _,
      ) {
        if (!revisionTwo.isCompleted && source.document.revision == 2) {
          revisionTwo.complete();
        }
      });

      harness.nats.registerHandler(_batchSubject, (bytes) async {
        final request = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(
          bytes,
        );
        final patch =
            request.operations.single
                as skir.AuthoringOperation_patchTagWrapper;
        expect(patch.value.color?.expected, Colors.blue.toSkirColor());
        expect(patch.value.color?.value, Colors.red.toSkirColor());

        harness
          ..sequence = 2
          ..tag = _tag(color: Colors.red)
          ..emitEvent(request.batchId);
        await revisionTwo.future.timeout(const Duration(seconds: 2));

        return harness.appliedResponse(request.batchId);
      });

      source.update(_colorPath, Colors.red.asValue);
      final result = await source.flush(paths: {_colorPath});

      expect(result, isA<MutationSuccess>());
      expect(source.document.revision, 2);
      expect(
        _documentTag(source.document).color.toARGB32(),
        Colors.red.toARGB32(),
      );
      expect(source.document.diagnostics, isEmpty);
      expect(source.saveState(_colorPath).phase, EditorSavePhase.saved);
      await waitForProvider(
        harness.container,
        canonicalTagProvider(_tagId),
        (value) => value.hasValue,
        description: "canonical tag after the applied event",
      );
      expect(
        harness.container
            .read(canonicalTagProvider(_tagId))
            .requireValue
            ?.color
            .toARGB32(),
        Colors.red.toARGB32(),
      );

      workSubscription.close();
      await harness.dispose();
    },
  );

  test(
    "applied color patch preserves an authoritative unpatched name",
    () async {
      final harness = _Harness.transportOnly();
      final source = harness.openDirectEditor();

      harness.nats.registerHandler(_batchSubject, (bytes) async {
        final request = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(
          bytes,
        );
        final patch =
            request.operations.single
                as skir.AuthoringOperation_patchTagWrapper;
        expect(patch.value.name, isNull);
        expect(patch.value.color?.expected, Colors.blue.toSkirColor());
        expect(patch.value.color?.value, Colors.red.toSkirColor());

        harness
          ..sequence = 2
          ..tag = _tag(name: "remote_name", color: Colors.red);

        return harness.appliedResponse(request.batchId);
      });

      source.update(_colorPath, Colors.red.asValue);
      final result = await source.flush(paths: {_colorPath});

      expect(result, isA<MutationSuccess>());
      expect(source.document.revision, 2);
      expect(_documentTag(source.document).name, "remote_name");
      expect(
        _documentTag(source.document).color.toARGB32(),
        Colors.red.toARGB32(),
      );
      expect(source.document.diagnostics, isEmpty);
      expect(source.saveState(_colorPath).phase, EditorSavePhase.saved);

      await harness.dispose();
    },
  );

  test("missing applied resource performs one authoritative refresh", () async {
    final harness = _Harness.transportOnly();
    final source = harness.openDirectEditor();

    harness.nats.registerHandler(_batchSubject, (bytes) async {
      final request = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(
        bytes,
      );
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _snapshotSubject,
        ),
        hasLength(1),
      );
      harness
        ..sequence = 2
        ..tag = _tag(name: "remote_name", color: Colors.red);
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createApplied(
          sequence: 2,
          batchId: request.batchId,
          changes: const [],
          indirectlyAffectedResources: const [],
        ),
      );
    });

    source.update(_colorPath, Colors.red.asValue);
    final result = await source.flush(paths: {_colorPath});

    expect(result, isA<MutationSuccess>());
    expect(source.document.revision, 2);
    expect(_documentTag(source.document).name, "remote_name");
    expect(
      harness.nats.requests.where(
        (request) => request.subject == _snapshotSubject,
      ),
      hasLength(2),
    );

    await harness.dispose();
  });
}
