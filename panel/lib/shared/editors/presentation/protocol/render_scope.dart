import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "render_scope.freezed.dart";

/// Receives a value update from a rendered input.
///
/// The callback receives the expression context and aliases active at the
/// input, allowing the owner boundary to canonicalize and validate the
/// destination before applying the mutation.
typedef BindingSetter = void Function(
  BindingReference reference,
  DataValue value,
  ExpressionContext context,
  Map<BindingId, BindingReference> aliases,
);

/// Routes an action to the owner of the current presentation tree.
///
/// The context and aliases are the values at the action site. The receiver
/// decides whether the action is local or crosses into the realm boundary.
typedef ActionExecutor = void Function(
  EditorAction action,
  ExpressionContext context,
  Map<BindingId, BindingReference> aliases,
);

/// Starts an interaction session for a binding, if its owner supports one.
///
/// Renderers use this boundary to bracket focus, commit, and cancellation
/// without owning draft history or persistence state.
typedef EditorInteractionStarter = EditorInteractionSession? Function(
  BindingReference reference,
);

/// Owns a temporary binding projected by a composite input.
///
/// Composite controls may expose a field that is not stored as an independent
/// resource value. This host keeps the projected snapshot locally, translates
/// edits back into the parent value, and reports replacements through
/// [onChanged]. It does not become the owner of the parent draft or revision.
final class VirtualBindingHost implements BindingSource {
  VirtualBindingHost({
    required this.id,
    required BindingSnapshot snapshot,
    required this.onChanged,
    this.interactionTarget,
  }) : _type = snapshot.type,
       _value = EditorValue.ready(snapshot.value),
       _revision = snapshot.revision,
       _writable = snapshot.writable;

  factory VirtualBindingHost.editorValue({
    required BindingId id,
    required TypeExpression type,
    required EditorValue value,
    required int revision,
    required bool writable,
    required ValueChanged<DataValue> onChanged,
    BindingReference? interactionTarget,
  }) => VirtualBindingHost._editorValue(
    id,
    type,
    value,
    revision,
    writable,
    onChanged,
    interactionTarget,
  );

  VirtualBindingHost._editorValue(
    this.id,
    this._type,
    this._value,
    this._revision,
    this._writable,
    this.onChanged,
    this.interactionTarget,
  );

  final BindingId id;
  final ValueChanged<DataValue> onChanged;
  final BindingReference? interactionTarget;
  final TypeExpression _type;
  EditorValue _value;
  int _revision;
  final bool _writable;
  @override
  bool get writable => _writable;
  @override
  int get revision => _revision;

  ExpressionContext bind(ExpressionContext context) {
    return context.withBinding(id, this);
  }

  @override
  TypeResult<BindingSourceState> inspect(
    DataPath path, {
    TypeRegistry? registry,
  }) => _value.inspectBindingValue(_type, path, registry: registry);

  BindingReference interactionReference(BindingReference reference) {
    if (reference.bindingId != id || interactionTarget == null) {
      return reference;
    }
    return interactionTarget!.at(reference.path);
  }

  /// Replaces a projected path and reports the resulting parent snapshot.
  ///
  /// Returns false when the path cannot be applied. A successful update changes
  /// only this host's projection; the callback forwards the replacement to the
  /// parent input, which remains authoritative for the actual draft.
  bool update(DataPath path, DataValue value) {
    final current = _value.valueOrNull;
    final updated = path.segments.isEmpty
        ? value
        : current == null
        ? null
        : path.replace(current, value).valueOrNull;
    if (updated == null) return false;

    _replace(updated);
    return true;
  }

  /// Executes a local action against the projected snapshot.
  ///
  /// The action sees bindings reconstructed from the current projection. When
  /// it succeeds, the affected value is written back through [update], while
  /// the parent editor still owns the resulting draft and revision.
  LocalMutationResult execute(
    LocalEditorAction action,
    ExpressionContext context, {
    required TypeRegistry registry,
    required ExpressionBudget budget,
    required Map<BindingId, BindingReference> aliases,
  }) {
    var current = context;
    for (final entry in context.bindings.bindings.entries) {
      final address = BindingReference(bindingId: entry.key)
          .canonicalizedWith(aliases);
      if (address.bindingId != id) continue;
      final root = _value.valueOrNull;
      final value = root == null ? null : address.path.read(root).valueOrNull;
      if (value == null) continue;
      final inspected = context.bindings.inspect(
        BindingReference(bindingId: entry.key),
        registry: registry,
      );
      if (inspected case TypeFailure(:final diagnostics)) {
        return LocalMutationInvalid(diagnostics);
      }
      final binding = inspected.valueOrNull!;
      current = current.withBinding(
        entry.key,
        BindingSnapshot(
          type: binding.type,
          value: value,
          revision: _revision,
          writable: binding.writable,
        ),
      );
    }
    final result = action.execute(current, registry: registry, budget: budget);
    if (result case LocalMutationApplied(:final value)) {
      final reference = action.action.mutationReference;
      final next = reference.path.read(value).valueOrNull;
      if (next != null) update(reference.canonicalizedWith(aliases).path, next);
    }
    return result;
  }

  void _replace(DataValue value) {
    _value = EditorValue.ready(value);
    _revision++;
    onChanged(value);
  }
}

/// A presentation definition resolved for a requested identifier or type.
///
/// [root] is rendered in a fresh scope when [inputs] are bound. [primaryInput]
/// identifies the value used when the definition is rendered as a typed field.
@freezed
abstract class ResolvedPresentationDefinition
    with _$ResolvedPresentationDefinition {
  const factory ResolvedPresentationDefinition({
    required PresentationId id,
    required PresentationNode root,
    @Default([]) List<PresentationInputParameter> inputs,
    BindingId? primaryInput,
  }) = _ResolvedPresentationDefinition;
}

/// Identifies one header expansion state within a composed presentation.
///
/// Node keys cover stable tree locations. Instance keys cover repeated or
/// invoked content whose rendered identity is supplied by the caller.
@freezed
sealed class HeaderExpansionKey with _$HeaderExpansionKey {
  const factory HeaderExpansionKey.node({
    required String nodeId,
    required BindingReference? binding,
  }) = NodeHeaderExpansionKey;

  const factory HeaderExpansionKey.instance(Object identity) =
      InstanceHeaderExpansionKey;
}

/// Owns transient expansion choices for headers in one composed editor.
///
/// Keys distinguish stable nodes from repeated or invoked presentation
/// instances. The store is intentionally separate from the immutable render
/// scope, and is discarded with the enclosing editor surface.
final class HeaderExpansionStore {
  final Map<HeaderExpansionKey, bool> _values = {};

  bool value({required HeaderExpansionKey key, required bool initial}) {
    return _values[key] ?? initial;
  }

  void set({required HeaderExpansionKey key, required bool expanded}) {
    _values[key] = expanded;
  }

  void remove(HeaderExpansionKey key) {
    _values.remove(key);
  }

  void clear() {
    _values.clear();
  }
}

/// Selects a presentation definition for a requested type and identifier.
///
/// The resolver owns fallback policy, including default presentations. A null
/// result means the caller must render the protocol's missing presentation
/// diagnostic or fallback rather than guessing a definition.
typedef PresentationResolver = ResolvedPresentationDefinition? Function(
  TypeExpression? type,
  PresentationId? requested,
);

/// Immutable capabilities and state passed through one presentation tree.
///
/// Bindings and actions remain routed to the enclosing editor owner. Derived
/// scopes may add aliases or virtual bindings, narrow access, disable input,
/// or enter read only mode, but cannot grant capabilities absent from the
/// parent scope. [expansionStore] is the sole owner of transient header state.
@freezed
abstract class PresentationRenderScope with _$PresentationRenderScope {
  const factory PresentationRenderScope({
    required ExpressionContext expressions,
    required TypeRegistry registry,
    required ExpressionBudget budget,
    required BindingSetter setBinding,
    required ActionExecutor executeAction,
    required PresentationResolver resolvePresentation,
    required HeaderExpansionStore expansionStore,
    EditorInteractionStarter? startInteraction,
    RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,
    ReferenceSearchSourceBuilder? referenceSearchSourceBuilder,
    ReferenceResourceResolver? resolveReferences,
    ReferenceEligibilityEvaluator? referenceEligibility,
    @Default([]) List<skir.ResourceId> referenceOrigins,
    @Default(ReferenceCandidatePolicyRegistry())
    ReferenceCandidatePolicyRegistry referencePolicies,
    EditOwner? Function(BindingReference reference)? editOwnerFor,
    RenderedBindingFocusController? bindingFocusController,
    @Default({})
    Map<PresentationCollectionSourceId, PresentationCollectionSource>
    collections,
    @Default({}) Map<BindingId, BindingReference> aliases,
    @Default({}) Map<BindingId, PresentationInputAccess> inputAccess,
    @Default({}) Map<BindingId, BindingReference?> ownerBindings,
    @Default({})
    Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,
    @Default({}) Set<(String, BindingReference?)> suppressedHeaders,
    @Default({}) Map<String, Widget> presentationSlots,
    Object? expansionIdentity,
    @Default(true) bool enabled,
    @Default(false) bool readOnly,
    @Default("local") String historyNamespace,
    @Default({}) Set<PresentationId> activePresentations,
  }) = _PresentationRenderScope;

  const PresentationRenderScope._();

  /// Resolves an alias to the binding address used by the enclosing owner.
  BindingReference canonical(BindingReference reference) {
    final alias = aliases[reference.bindingId];
    if (alias == null) return reference;
    return alias.at(reference.path);
  }

  /// Returns lexical access without granting undeclared edit capability.
  PresentationInputAccess accessOf(BindingReference reference) =>
      inputAccess[reference.bindingId] ?? PresentationInputAccess.read;

  /// Resolves the transaction origin, including inputs with a virtual representation.
  BindingReference? ownerReference(BindingReference reference) =>
      ownerBindings[reference.bindingId]?.at(reference.path);

  TypeResult<ResolvedBinding> resolve(BindingReference reference) =>
      expressions.bindings.resolve(reference, registry: registry);

  TypeResult<InspectedBinding> inspect(BindingReference reference) =>
      expressions.bindings.inspect(reference, registry: registry);

  TypeResult<DataValue> evaluate(TypedExpression expression) =>
      expression.evaluate(expressions, registry: registry, budget: budget);

  String expressionText(TypedExpression expression) {
    final value = evaluate(expression).valueOrNull;
    return value == null ? "" : value.expressionDisplayText;
  }

  List<ShortcutActivator> shortcuts(
    HeaderItemId itemId,
    HeaderItemCommand command,
  ) =>
      headerShortcuts[HeaderItemCommandId(itemId: itemId, command: command)] ??
      const [];

  /// Sends an input value to the draft owner when this scope permits editing.
  ///
  /// Disabled and read only scopes absorb updates. This keeps presentation
  /// policy at the tree boundary instead of requiring every control to repeat
  /// the same guard.
  void update(BindingReference reference, DataValue value) {
    if (!enabled || readOnly) return;
    setBinding(reference, value, expressions, aliases);
  }

  /// Routes an action unless this scope has disabled it or is read only for a
  /// local action. Realm actions remain eligible in read only presentations.
  void invoke(EditorAction action) {
    if (!enabled) return;
    if (readOnly && action is LocalEditorAction) return;
    executeAction(action, expressions, aliases);
  }

  /// Begins an interaction at the canonical owner address, when supported.
  EditorInteractionSession? beginInteraction(BindingReference reference) =>
      startInteraction?.call(canonical(reference));

  /// Adds a lexical alias while preserving the source owner's access policy.
  PresentationRenderScope withAlias(
    BindingId id,
    BindingReference source,
    BindingSource bindingSource,
  ) => copyWith(
    expressions: expressions.withBinding(id, bindingSource),
    aliases: {...aliases, id: canonical(source)},
    inputAccess: {...inputAccess, id: accessOf(source)},
    ownerBindings: {...ownerBindings, id: ownerReference(source)},
  );

  /// Derives a scope whose virtual binding writes back through [host].
  ///
  /// Only local actions targeting that binding are intercepted. Other actions
  /// continue to the enclosing owner.
  PresentationRenderScope withVirtualBinding(
    VirtualBindingHost host, {
    BindingReference? source,
  }) {
    return copyWith(
      expressions: host.bind(expressions),
      inputAccess: {
        ...inputAccess,
        host.id: source == null
            ? (host.writable
                  ? PresentationInputAccess.edit
                  : PresentationInputAccess.read)
            : accessOf(source),
      },
      ownerBindings: {
        ...ownerBindings,
        host.id: source == null ? null : ownerReference(source),
      },
      startInteraction: (reference) {
        return startInteraction?.call(host.interactionReference(reference));
      },
      setBinding: (reference, value, context, aliases) {
        final destination = reference.canonicalizedWith(aliases);
        if (destination.bindingId != host.id) {
          setBinding(reference, value, context, aliases);
          return;
        }
        host.update(destination.path, value);
      },
      executeAction: (action, context, aliases) {
        if (action case LocalEditorAction(action: final local)) {
          final reference = local.mutationReference;
          final destination = reference.canonicalizedWith(aliases);
          if (destination.bindingId == host.id) {
            host.execute(
              action,
              context,
              registry: registry,
              budget: budget,
              aliases: aliases,
            );
            return;
          }
        }
        executeAction(action, context, aliases);
      },
    );
  }
}
