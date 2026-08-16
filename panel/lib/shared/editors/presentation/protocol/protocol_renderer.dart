import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef RealmActionExecutor =
    FutureOr<TypedMutationResult> Function(RealmAction action);

final _defaultEditorHeaderShortcuts =
    Map<HeaderItemCommandId, List<ShortcutActivator>>.unmodifiable({
      HeaderItemCommandId(
        itemId: listItemReorderHeaderItemId,
        command: HeaderItemCommand.moveBefore,
      ): const [
        SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
        SingleActivator(LogicalKeyboardKey.keyK, alt: true),
      ],
      HeaderItemCommandId(
        itemId: listItemReorderHeaderItemId,
        command: HeaderItemCommand.moveAfter,
      ): const [
        SingleActivator(LogicalKeyboardKey.arrowDown, alt: true),
        SingleActivator(LogicalKeyboardKey.keyJ, alt: true),
      ],
    });

class EditorProtocolRenderer extends StatefulWidget {
  const EditorProtocolRenderer({
    required this.envelope,
    required this.typeCatalog,
    this.conversions = const [],
    this.realmActions = const [],
    this.presentations = const [],
    this.collections = const [],
    this.presentation,
    this.diagnostics = const [],
    this.onRealmAction,
    this.realmSearchSourceBuilder,
    this.headerShortcuts = const {},
    this.readOnly = false,
    this.historyNamespace = "local",
    super.key,
  });

  final TypedValueEnvelope envelope;
  final TypeCatalog typeCatalog;
  final List<ConversionDefinition> conversions;
  final List<RealmActionDefinition> realmActions;
  final List<PresentationDefinition> presentations;
  final List<PresentationCollectionSource> collections;
  final PresentationNode? presentation;
  final List<TypeDiagnostic> diagnostics;
  final RealmActionExecutor? onRealmAction;
  final RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder;
  final Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts;
  final bool readOnly;
  final String historyNamespace;

  @override
  State<EditorProtocolRenderer> createState() => _EditorProtocolRendererState();
}

class _EditorProtocolRendererState extends State<EditorProtocolRenderer> {
  late final TransactionalEditorSource _source;

  @override
  void initState() {
    super.initState();
    _source = _createSource();
  }

  @override
  void didUpdateWidget(EditorProtocolRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.envelope == widget.envelope &&
        oldWidget.typeCatalog == widget.typeCatalog &&
        oldWidget.presentations == widget.presentations &&
        oldWidget.collections == widget.collections &&
        oldWidget.presentation == widget.presentation &&
        oldWidget.diagnostics == widget.diagnostics &&
        oldWidget.readOnly == widget.readOnly) {
      return;
    }
    final revision = oldWidget.envelope.rootValue == widget.envelope.rootValue
        ? _source.document.revision
        : _source.document.revision + 1;
    _source.refreshDocument(_createDocument(revision));
  }

  @override
  Widget build(BuildContext context) {
    return EditorSurface(
      source: _source,
      conversions: widget.conversions,
      realmSearchSourceBuilder: widget.realmSearchSourceBuilder,
      headerShortcuts: {
        ..._defaultEditorHeaderShortcuts,
        ...widget.headerShortcuts,
      },
      readOnly: widget.readOnly,
      historyNamespace: widget.historyNamespace,
    );
  }

  TransactionalEditorSource _createSource() {
    return TransactionalEditorSource(
      document: _createDocument(0),
      debounce: Duration.zero,
      successfulSavePhase: EditorSavePhase.sessionOnly,
      commit: (commit) async {
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
      executeRealmAction: _executeRealm,
    );
  }

  EditorDocument _createDocument(int revision) {
    final rootType = NamedType(widget.envelope.rootType);
    final registry = TypeRegistry(widget.typeCatalog);
    final resolved = registry.resolve(rootType);
    return EditorDocument(
      rootType: rootType,
      typeCatalog: widget.typeCatalog,
      confirmedValue: widget.envelope.rootValue,
      revision: revision,
      presentations: widget.presentations,
      collections: widget.collections,
      rootPresentation: widget.presentation,
      diagnostics: [...widget.diagnostics, ...resolved.diagnostics],
      readOnly: widget.readOnly,
    );
  }

  Future<TypedMutationResult> _executeRealm(
    RealmAction action,
    ExpressionContext context,
  ) async {
    final executor = widget.onRealmAction;
    if (executor == null) return _unavailable("Realm actions are unavailable");
    if (action case InvokeRealmCallbackAction(
      :final actionId,
      :final payload,
    )) {
      final definition = widget.realmActions
          .where((candidate) => candidate.id == actionId)
          .firstOrNull;
      if (definition == null) return _unavailable("Realm action is unknown");
      final evaluated = payload.evaluate(
        context,
        registry: TypeRegistry(widget.typeCatalog),
      );
      if (evaluated case TypeFailure(:final diagnostics)) {
        return TypedMutationResult.invalid(diagnostics);
      }
      final diagnostics = evaluated.valueOrNull!.validateAgainst(
        NamedType(definition.payloadType),
        registry: TypeRegistry(widget.typeCatalog),
      );
      if (diagnostics.isNotEmpty) {
        return TypedMutationResult.invalid(diagnostics);
      }
    }
    return executor(action);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }
}

TypedMutationResult _unavailable(String message) {
  return TypedMutationResult.unavailable([
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
  ]);
}
