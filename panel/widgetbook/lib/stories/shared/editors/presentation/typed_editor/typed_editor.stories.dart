import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/misc.dart" show Override;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

class EditorStories extends StatelessWidget {
  const EditorStories({
    required this.child,
    this.overrides = const [],
    this.source,
    super.key,
  });

  final Widget child;
  final List<Override> overrides;
  final EditorSource Function(Ref ref)? source;

  @override
  Widget build(BuildContext context) {
    return FakeApp(
      overrides: overrides,
      child: Consumer(
        child: child,
        builder: (context, ref, child) => EditorRoot(
          create: (ref) => source?.call(ref) ?? SelectionEditorSource(ref),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Section(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
              ActionRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class EditorStory extends StatelessWidget {
  const EditorStory({required this.rootType, this.initialValue, super.key});

  final RecordType rootType;
  final RecordValue? initialValue;

  @override
  Widget build(BuildContext context) {
    final initial = initialValue ?? rootType.createInitialValue().valueOrNull;
    return EditorStories(
      source: (_) => _StoryEditorSource(
        rootType: rootType,
        state: initial is RecordValue ? EditorValue.ready(initial) : null,
      ),
      child: const SingleChildScrollView(child: TypedEditor()),
    );
  }
}

@widgetbook.UseCase(name: "Loading", type: TypedEditor)
Widget loadingEditorUseCase(BuildContext context) => EditorStories(
  source: (_) =>
      _StoryEditorSource(rootType: StringType(), state: EditorValue.loading()),
  child: const TypedEditor(),
);

@widgetbook.UseCase(name: "Conflict", type: TypedEditor)
Widget conflictValueEditorUseCase(BuildContext context) => EditorStories(
  source: (_) =>
      _StoryEditorSource(rootType: StringType(), state: EditorValue.conflict()),
  child: const TypedEditor(),
);

@widgetbook.UseCase(name: "Invalid", type: TypedEditor)
Widget invalidValueEditorUseCase(BuildContext context) => EditorStories(
  source: (_) => _StoryEditorSource(
    rootType: StringType(),
    state: EditorValue.invalid([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "The editor value is missing",
      ),
    ]),
  ),
  child: const TypedEditor(),
);

@widgetbook.UseCase(name: "Ready", type: TypedEditor)
Widget readyValueEditorUseCase(BuildContext context) => EditorStories(
  source: (_) => _StoryEditorSource(
    rootType: StringType(),
    state: EditorValue.ready(StringValue("Typed value")),
  ),
  child: const TypedEditor(),
);

class _StoryEditorSource extends ChangeNotifier implements EditorSource {
  _StoryEditorSource({required this.rootType, EditorValue? state})
    : _state =
          state ??
          EditorValue.invalid([
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "The story could not create an initial value",
            ),
          ]);

  final TypeExpression rootType;

  @override
  EditorDocument get document => EditorDocument(
    rootType: rootType,
    typeCatalog: const TypeCatalog([]),
    confirmedValue: _state.valueOrNull ?? const UnitValue(),
    revision: 0,
  );
  final EditorValue _state;

  @override
  EditorValue value(DataPath path) => _state;

  @override
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) => EditorMutationResult.applied(value);

  @override
  void refreshDocument(EditorDocument document) {}

  @override
  EditorInteractionSession beginInteraction(DataPath path) =>
      _StoryInteraction(path);

  @override
  EditorSaveState saveState(DataPath path) => const EditorSaveState.idle();

  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async =>
      TypedMutationResult.success(
        revision: 0,
        value: _state.valueOrNull ?? const UnitValue(),
      );

  @override
  Future<EditorActionResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async => LocalEditorActionResult(_unavailable());

  @override
  void acceptRemote({required int revision, required DataValue value}) {}

  @override
  void acceptRemoteDeletion() {}

  @override
  void useRemote(DataPath path) {}

  @override
  Future<TypedMutationResult> keepLocal(DataPath path) async => _unavailable();
}

final class _StoryInteraction implements EditorInteractionSession {
  _StoryInteraction(this.path);

  @override
  final DataPath path;
  @override
  bool active = true;

  @override
  void cancel() => active = false;

  @override
  Future<TypedMutationResult> commit() async {
    active = false;
    return _unavailable();
  }
}

TypedMutationResult _unavailable() => TypedMutationResult.unavailable([
  const TypeDiagnostic(
    code: TypeDiagnosticCode.invalidValue,
    message: "Story persistence is unavailable",
  ),
]);
