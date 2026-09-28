import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Executes a realm action after the renderer has evaluated and validated its
/// payload. The callback owns the external command boundary and returns the
/// result that the presentation surface can display or apply as instructions.
typedef RealmActionExecutor = FutureOr<RealmCommandResult> Function(
  RealmAction action,
  DataValue? payload,
);

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

/// Renders a serialized typed value using the editor presentation protocol.
///
/// The envelope and catalog are the canonical input snapshot. In editable
/// mode this widget creates and owns one [LocalEditor], then disposes it when
/// the envelope or mode changes. In read only mode no local draft exists and
/// the model renders the envelope value directly. Realm actions are validated
/// against the supplied capability catalog before being delegated to
/// [onRealmAction]; unavailable capabilities become presentation diagnostics.
class EditorProtocolRenderer extends StatefulWidget {
  const EditorProtocolRenderer({
    required this.envelope,
    required this.typeCatalog,
    this.conversions = const [],
    this.capabilities = const [],
    this.presentations = const [],
    this.collections = const [],
    this.presentation,
    this.diagnostics = const [],
    this.onRealmAction,
    this.concreteTypeInitializer,
    this.realmSearchSourceBuilder,
    this.executePanelInstruction,
    this.headerShortcuts = const {},
    this.readOnly = false,
    this.historyNamespace = "local",
    super.key,
  });

  final TypedValueEnvelope envelope;
  final TypeCatalog typeCatalog;
  final List<ConversionDefinition> conversions;
  final List<CapabilityDefinition> capabilities;
  final List<PresentationDefinition> presentations;
  final List<PresentationCollectionSource> collections;
  final PresentationNode? presentation;
  final List<TypeDiagnostic> diagnostics;
  final RealmActionExecutor? onRealmAction;
  final ConcreteTypeInitializer? concreteTypeInitializer;
  final RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder;
  final FutureOr<void> Function(PanelInstruction instruction)?
  executePanelInstruction;
  final Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts;
  final bool readOnly;
  final String historyNamespace;

  @override
  State<EditorProtocolRenderer> createState() => _EditorProtocolRendererState();
}

class _EditorProtocolRendererState extends State<EditorProtocolRenderer> {
  LocalEditor? _local;

  @override
  void initState() {
    super.initState();
    _replaceLocal();
  }

  void _replaceLocal() {
    _local?.dispose();
    _local = widget.readOnly
        ? null
        : LocalEditor(
            rootType: NamedType(widget.envelope.rootType),
            typeCatalog: widget.typeCatalog,
            value: widget.envelope.rootValue,
            concreteTypeInitializer: widget.concreteTypeInitializer,
          );
  }

  @override
  void didUpdateWidget(EditorProtocolRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.envelope != widget.envelope ||
        oldWidget.readOnly != widget.readOnly) {
      _replaceLocal();
    } else {
      _local?.refreshSchema(
        NamedType(widget.envelope.rootType),
        widget.typeCatalog,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = _local == null
        ? PresentationModel.value(
            type: NamedType(widget.envelope.rootType),
            value: widget.envelope.rootValue,
            catalog: widget.typeCatalog,
            presentation: widget.presentation,
            presentations: widget.presentations,
            collections: widget.collections,
            diagnostics: widget.diagnostics,
          )
        : PresentationModel.editor(
            owner: _local!,
            presentation: widget.presentation,
            presentations: widget.presentations,
            collections: widget.collections,
            diagnostics: widget.diagnostics,
          );
    return ComposedEditor(
      key: ObjectKey(_local ?? widget.envelope),
      model: model,
      host: EditorHostCapabilities(
        realmActions: RealmActionCapabilities(
          execute: _executeRealm,
          executePanelInstruction: widget.executePanelInstruction,
        ),
        presentationSearch: widget.realmSearchSourceBuilder == null
            ? null
            : RealmPresentationSearchCapabilities(
                source: widget.realmSearchSourceBuilder!,
              ),
      ),
      conversions: widget.conversions,
      headerShortcuts: {
        ..._defaultEditorHeaderShortcuts,
        ...widget.headerShortcuts,
      },
      historyNamespace: widget.historyNamespace,
      readOnly: widget.readOnly,
    );
  }

  Future<RealmCommandResult> _executeRealm(
    RealmAction action,
    ExpressionContext context,
  ) async {
    final executor = widget.onRealmAction;
    if (executor == null) {
      return _commandUnavailable("Realm actions are unavailable");
    }
    DataValue? evaluatedPayload;
    if (action case InvokeRealmCommandAction(
      :final capabilityId,
      :final payload,
    )) {
      final definition = widget.capabilities
          .whereType<CommandCapabilityDefinition>()
          .where((candidate) => candidate.id == capabilityId)
          .firstOrNull;
      if (definition == null) {
        return _commandUnavailable("Realm command capability is unknown");
      }
      final evaluated = payload.evaluate(
        context,
        registry: TypeRegistry(widget.typeCatalog),
      );
      if (evaluated case TypeFailure(:final diagnostics)) {
        return RealmCommandResult.invalid(diagnostics);
      }

      evaluatedPayload = evaluated.valueOrNull;
      final diagnostics = evaluated.valueOrNull!.validateAgainst(
        NamedType(definition.requestType),
        registry: TypeRegistry(widget.typeCatalog),
      );
      if (diagnostics.isNotEmpty) {
        return RealmCommandResult.invalid(diagnostics);
      }
    }
    return executor(action, evaluatedPayload);
  }

  @override
  void dispose() {
    _local?.dispose();
    super.dispose();
  }
}

RealmCommandResult _commandUnavailable(String message) {
  return RealmCommandResult.unavailable([
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
  ]);
}
