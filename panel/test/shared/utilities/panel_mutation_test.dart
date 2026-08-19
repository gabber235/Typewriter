import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  late FlutterExceptionHandler? previousErrorHandler;
  late List<FlutterErrorDetails> reports;

  setUp(() {
    previousErrorHandler = FlutterError.onError;
    reports = [];
    FlutterError.onError = reports.add;
  });

  tearDown(() => FlutterError.onError = previousErrorHandler);

  test("returns known results without reporting them", () async {
    final expected = invalidMutation("Keep this exact diagnostic");

    final result = await runPanelMutation(
      operation: PanelMutationOperation.updateService,
      mutation: () async => expected,
    );

    expect(result, same(expected));
    expect(reports, isEmpty);
  });

  test(
    "reports an unexpected failure once with safe operation context",
    () async {
      final failure = StateError("private transport detail");

      final result = await runPanelMutation<String?>(
        operation: PanelMutationOperation.updateTag,
        mutation: () async => throw failure,
        recover: (_, _) => null,
      );

      expect(result, isNull);
      expect(reports, hasLength(1));
      expect(reports.single.exception, same(failure));
      expect(reports.single.context.toString(), "while updating a tag");
      expect(
        reports.single.context.toString(),
        isNot(contains("private transport detail")),
      );
    },
  );

  test("rethrows an unrecovered failure with its original stack", () async {
    final failure = StateError("transport failed");
    late StackTrace originalStack;

    Future<void> fail() async {
      try {
        throw failure;
      } on Object catch (_, stackTrace) {
        originalStack = stackTrace;
        rethrow;
      }
    }

    Object? caught;
    StackTrace? caughtStack;
    try {
      await runPanelMutation(
        operation: PanelMutationOperation.signOut,
        mutation: fail,
      );
    } on Object catch (error, stackTrace) {
      caught = error;
      caughtStack = stackTrace;
    }

    expect(caught, same(failure));
    expect(caughtStack.toString(), originalStack.toString());
    expect(reports, hasLength(1));
  });
}
