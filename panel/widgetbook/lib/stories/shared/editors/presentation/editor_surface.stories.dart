import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

enum _CommitOutcome { succeed, fail, conflict }

@widgetbook.UseCase(name: "Default", type: EditorSurface)
Widget defaultEditorSurfaceUseCase(BuildContext context) {
  final outcome = context.knobs.object.dropdown(
    label: "Commit outcome",
    options: _CommitOutcome.values,
    initialOption: _CommitOutcome.succeed,
    labelBuilder: (value) => value.name,
  );
  final latency = context.knobs.duration(
    label: "Commit latency",
    initialValue: const Duration(milliseconds: 600),
  );
  final readOnly = context.knobs.boolean(label: "Read only");
  return FakeApp(
    child: _EditorSurfaceStory(
      outcome: outcome,
      latency: latency,
      readOnly: readOnly,
    ),
  );
}

class _EditorSurfaceStory extends HookWidget {
  const _EditorSurfaceStory({
    required this.outcome,
    required this.latency,
    required this.readOnly,
  });

  final _CommitOutcome outcome;
  final Duration latency;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(
      () => EditorController(
        source: TransactionalEditorSource(
          document: _storyDocument(),
          commit: (commit) => _commitStory(commit, outcome, latency),
        ),
      ),
    );
    useEffect(() => controller.dispose, [controller]);
    return Center(
      child: Section(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: EditorSurface(controller: controller, readOnly: readOnly),
            ),
          ),
        ),
      ),
    );
  }
}

EditorDocument _storyDocument() => EditorDocument(
  rootType: RecordType(
    fields: {
      "title": TypeField(name: "title", type: StringType()),
      "summary": TypeField(name: "summary", type: StringType()),
      "enabled": TypeField(name: "enabled", type: BooleanType()),
      "priority": const TypeField(
        name: "priority",
        type: IntegerType(width: IntegerWidth.signed32),
      ),
    },
  ),
  typeCatalog: const TypeCatalog([]),
  confirmedValue: RecordValue({
    "title": const StringValue("Greet the innkeeper"),
    "summary": const StringValue("Walk up to the innkeeper and say hello."),
    "enabled": const BooleanValue(true),
    "priority": IntegerValue(BigInt.two),
  }),
  revision: 0,
);

Future<TypedMutationResult> _commitStory(
  EditorCommit commit,
  _CommitOutcome outcome,
  Duration latency,
) async {
  await Future<void>.delayed(latency);
  return switch (outcome) {
    _CommitOutcome.succeed => TypedMutationResult.success(
      revision: commit.expectedRevision + 1,
      value: commit.rootValue,
    ),
    _CommitOutcome.fail => TypedMutationResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "The story server rejected this save",
      ),
    ]),
    _CommitOutcome.conflict => TypedMutationResult.conflict(
      expectedRevision: commit.expectedRevision,
      actualRevision: commit.expectedRevision + 1,
      actualValue: _remoteValue(commit.rootValue),
    ),
  };
}

DataValue _remoteValue(DataValue local) {
  if (local is! RecordValue) return local;
  return local.withField(
    "title",
    const StringValue("Greet the innkeeper (remote)"),
  );
}
