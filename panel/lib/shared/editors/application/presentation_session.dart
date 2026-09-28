/*
 * Bridges a presentation model to the editor owners that supply its bindings.
 *
 * The session owns listener wiring and the binding generation used by
 * expression evaluation. Edit owners remain authoritative for draft state,
 * validation, interaction gates, and persistence. Replacing the model changes
 * routing and invalidates binding observations, but never recreates or resets
 * those owners.
 */
import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns presentation subscriptions and routes presentation operations to the
/// supplied edit owners.
///
/// The session is the bridge between binding references in a presentation and
/// owners stored in its inputs. It owns listener wiring and binding revisions,
/// while each owner remains authoritative for draft state and persistence.
/// Refreshing a model therefore preserves the supplied owners and their active
/// interaction state.
final class PresentationSession extends ChangeNotifier {
  PresentationSession(PresentationModel model) : _model = model {
    _attach();
  }

  PresentationModel _model;

  /// The model currently used to resolve presentation bindings and actions.
  PresentationModel get model => _model;
  final Set<EditOwner> _owners = {};
  int _generation = 0;
  int get generation => _generation;

  /// Replaces presentation routing while retaining the existing edit owners.
  ///
  /// Listeners are rewired before notification. The generation advances so
  /// binding snapshots created after the refresh cannot be confused with
  /// observations from the previous model.
  void refresh(PresentationModel model) {
    for (final owner in _owners) {
      owner.removeListener(_ownerChanged);
    }
    _owners.clear();
    _model = model;
    _generation++;

    _attach();
    notifyListeners();
  }

  void _ownerChanged() {
    _generation++;
    notifyListeners();
  }

  void _attach() {
    for (final input in _model.inputs.values) {
      if (input case PresentationEditInput(:final owner)) {
        if (_owners.add(owner)) owner.addListener(_ownerChanged);
      }
    }
  }

  /// Finds the owner behind a binding reference, if that input is editable.
  EditOwner? owner(BindingReference reference) =>
      switch (_model.inputs[reference.bindingId]) {
        PresentationEditInput(:final owner) => owner,
        _ => null,
      };

  /// Builds the expression environment backed by current value inputs and
  /// live edit owners.
  BindingEnvironment get bindings {
    final sources = <BindingId, BindingSource>{};
    for (final entry in model.inputs.entries) {
      switch (entry.value) {
        case PresentationValueInput(:final type, :final value):
          sources[entry.key] = EditorValueBindingSource(
            type: type,
            value: value,
            revision: _generation,
          );
        case PresentationEditInput(:final owner, :final path):
          sources[entry.key] = EditOwnerBindingSource(
            owner: owner,
            prefix: path,
            revision: _generation,
          );
      }
    }
    return BindingEnvironment(sources);
  }

  /// Applies a presentation edit after resolving its input path.
  ///
  /// The reference path is relative to the input. Structural intent is
  /// prefixed with the same input path so later persistence can preserve list,
  /// map, and polymorphic operations.
  EditorMutationResult update(
    BindingReference reference,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    final target = owner(reference);
    if (target == null || target.readOnly) {
      return EditorMutationResult.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "Binding has no writable edit owner",
        ),
      ]);
    }
    final input = model.inputs[reference.bindingId]! as PresentationEditInput;
    return target.update(
      input.path.followedBy(reference.path),
      value,
      structuralMutation: structuralMutation?.prefixedBy(input.path),
    );
  }

  /// Starts an interaction on an editable presentation binding.
  ///
  /// The returned session belongs to the underlying owner. A value input has no
  /// interaction lifecycle and returns `null`.
  EditorInteractionSession? beginInteraction(BindingReference reference) {
    final input = model.inputs[reference.bindingId];
    return input is PresentationEditInput
        ? input.owner.beginInteraction(input.path.followedBy(reference.path))
        : null;
  }

  /// Executes a local presentation action and routes its result to its owner.
  ///
  /// Multi owner actions are evaluated independently for each owner, then
  /// applied only after every member validates successfully. This keeps a
  /// shared presentation from partially changing its selection.
  EditorMutationResult executeLocal(
    LocalEditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) {
    final destination = action.action.mutationReference.canonicalizedWith(
      aliases,
    );
    final target = owner(destination);
    if (target is EditorStructureOwner) {
      final structural = _executeStructuralDraftAction(
        target,
        destination,
        action.action,
        context,
        aliases,
      );
      if (structural != null) return structural;
    }
    if (action.action case final ReplaceConcreteTypeAction replacement
        when target is! EditorStructureOwner) {
      final concrete = _replaceConcreteType(
        target,
        destination,
        replacement,
        context,
      );
      if (concrete != null) return concrete;
    }
    if (target is MultiEditOwner) {
      final input =
          model.inputs[destination.bindingId]! as PresentationEditInput;
      final destinationPath = input.path.followedBy(destination.path);
      final prepared = <(EditOwner, DataValue, EditorStructuralMutation?)>[];
      for (final member in target.owners) {
        final sources = {...context.bindings.bindings};
        for (final entry in sources.entries.toList()) {
          final address = BindingReference(bindingId: entry.key)
              .canonicalizedWith(aliases);
          if (address.bindingId != destination.bindingId) continue;
          final input =
              model.inputs[address.bindingId]! as PresentationEditInput;
          final value = member
              .value(input.path.followedBy(address.path))
              .valueOrNull;

          if (value == null) return const EditorMutationResult.conflict();
          final inspected = context.bindings.inspect(
            BindingReference(bindingId: entry.key),
            registry: TypeRegistry(model.catalog),
          );
          if (inspected case TypeFailure(:final diagnostics)) {
            return EditorMutationResult.invalid(diagnostics);
          }
          final binding = inspected.valueOrNull!;
          sources[entry.key] = BindingSnapshot(
            type: binding.type,
            value: value,
            revision: binding.revision,
            writable: !member.readOnly,
          );
        }
        final memberContext = context.copyWith(
          bindings: BindingEnvironment(sources),
        );
        final registry = TypeRegistry(member.typeCatalog);

        final result = action.execute(memberContext, registry: registry);
        if (result case LocalMutationInvalid(:final diagnostics)) {
          return EditorMutationResult.invalid(diagnostics);
        }

        final local = action.action.mutationReference;
        final value = local.path
            .read((result as LocalMutationApplied).value)
            .valueOrNull;

        if (value == null) return const EditorMutationResult.conflict();
        final prefix = BindingReference(bindingId: local.bindingId)
            .canonicalizedWith(aliases)
            .path;

        final validation = member.validate(destinationPath, value);

        if (validation is! AppliedEditorMutation) return validation;
        prepared.add((
          member,
          validation.value,
          structuralMutationFor(
            action.action,
            memberContext,
            result,
            registry,
          )?.prefixedBy(input.path.followedBy(prefix)),
        ));
      }
      for (final (member, value, mutation) in prepared) {
        final result = member.update(
          destinationPath,
          value,
          structuralMutation: mutation,
        );
        if (result is! AppliedEditorMutation) return result;
      }
      return EditorMutationResult.applied(prepared.first.$2);
    }
    final registry = TypeRegistry(model.catalog);

    final result = action.execute(context, registry: registry);
    if (result case LocalMutationInvalid(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }

    final applied = result as LocalMutationApplied;

    final local = action.action.mutationReference;

    final canonical = local.canonicalizedWith(aliases);

    final value = local.path.read(applied.value);
    if (value case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    final prefix = DataPath.root.followedBy(
      BindingReference(bindingId: local.bindingId)
          .canonicalizedWith(aliases)
          .path,
    );
    final structural = structuralMutationFor(
      action.action,
      context,
      result,
      registry,
    )?.prefixedBy(prefix);
    return update(
      canonical,
      value.valueOrNull!,
      structuralMutation: structural,
    );
  }

  EditorMutationResult? _replaceConcreteType(
    EditOwner? owner,
    BindingReference destination,
    ReplaceConcreteTypeAction action,
    ExpressionContext context,
  ) {
    if (owner == null) return null;
    final input = model.inputs[destination.bindingId];
    if (input is! PresentationEditInput) return null;
    final registry = TypeRegistry(model.catalog);
    final inspected = context.bindings.inspect(destination, registry: registry);
    if (inspected case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    final declared = inspected.valueOrNull!.type;
    if (declared is! NamedType ||
        !NamedType(action.concreteType)
            .isStructurallyAssignableTo(declared, registry)) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Concrete type does not refine the declared type",
          path: destination.path,
        ),
      ]);
    }
    final resolved = registry.resolveExact(action.concreteType).valueOrNull;
    if (resolved == null || !resolved.isConcrete) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Concrete type is unavailable",
          path: destination.path,
        ),
      ]);
    }
    final initial = resolved.representation.createInitialValue(
      registry: registry,
    );
    if (initial case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    final path = input.path.followedBy(destination.path);
    return owner.update(
      path,
      PolymorphicValue(
        concreteType: action.concreteType,
        value: initial.valueOrNull!,
      ),
      structuralMutation: EditorReplaceConcreteType(
        path,
        action.concreteType,
        initial.valueOrNull!,
      ),
    );
  }

  EditorMutationResult? _executeStructuralDraftAction(
    EditorStructureOwner owner,
    BindingReference destination,
    LocalAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) {
    final input = model.inputs[destination.bindingId];
    if (input is! PresentationEditInput) return null;
    final path = input.path.followedBy(destination.path);
    DataValue? evaluate(TypedExpression expression) => expression
        .evaluate(context, registry: TypeRegistry(model.catalog))
        .valueOrNull;

    int? integer(TypedExpression expression) {
      final value = evaluate(expression);
      return value is IntegerValue ? value.value.toInt() : null;
    }

    return switch (action) {
      AppendListItemAction(:final value) => _appendDraftList(
        owner,
        path,
        evaluate(value),
      ),
      RemoveListItemAction(:final index) => _withInteger(
        integer(index),
        (value) => owner.removeListItem(path, value),
      ),
      DuplicateListItemAction(:final source) => _draftListSource(
        source.canonicalizedWith(aliases),
        input.path,
        owner.duplicateListItem,
      ),
      ReorderListItemAction(:final source, :final newIndex) => _withInteger(
        integer(newIndex),
        (destinationIndex) => _draftListSource(
          source.canonicalizedWith(aliases),
          input.path,
          (path, sourceIndex) =>
              owner.reorderListItem(path, sourceIndex, destinationIndex),
        ),
      ),
      PutMapEntryAction(key: final key, value: final value) => _putDraftMap(
        owner,
        path,
        evaluate(key),
        evaluate(value),
      ),
      RemoveMapEntryAction(:final key) => _removeDraftMap(
        owner,
        path,
        evaluate(key),
      ),
      ReplaceConcreteTypeAction() => const EditorMutationResult.conflict(),
      SetValueAction() || InsertListItemAction() => null,
    };
  }

  @override
  void dispose() {
    for (final owner in _owners) {
      owner.removeListener(_ownerChanged);
    }
    _owners.clear();
    _generation++;
    super.dispose();
  }
}

EditorMutationResult _appendDraftList(
  EditorStructureOwner owner,
  DataPath path,
  DataValue? value,
) {
  final index = owner.listStructure(path)?.items.length;
  final appended = owner.appendListItem(path);
  if (appended is! AppliedEditorMutation || index == null || value == null) {
    return appended;
  }
  return owner.update(path.index(index), value);
}

EditorMutationResult _putDraftMap(
  EditorStructureOwner owner,
  DataPath path,
  DataValue? key,
  DataValue? value,
) {
  final appended = owner.appendMapEntry(path);
  if (appended is! AppliedEditorMutation) return appended;
  final entry = owner.mapStructure(path)?.entries.lastOrNull;
  if (entry == null) return appended;
  if (key != null) owner.updateMapKey(path, entry.id, key);
  if (value != null) owner.updateMapValue(path, entry.id, value);
  return appended;
}

EditorMutationResult? _removeDraftMap(
  EditorStructureOwner owner,
  DataPath path,
  DataValue? key,
) {
  if (key == null) return null;
  final entries = owner.mapStructure(path)?.entries;
  if (entries == null) return null;
  final byId = key is IntegerValue
      ? entries
            .where((entry) => entry.id.value == key.value.toInt())
            .firstOrNull
      : null;
  final entry =
      byId ??
      entries.where((entry) => entry.key.valueOrNull == key).firstOrNull;
  return entry == null ? null : owner.removeMapEntry(path, entry.id);
}

EditorMutationResult? _draftListSource(
  BindingReference source,
  DataPath inputPrefix,
  EditorMutationResult Function(DataPath path, int index) apply,
) {
  final segments = source.path.segments;
  if (segments.isEmpty || segments.last is! IndexPathSegment) return null;
  final index = (segments.last as IndexPathSegment).index;
  final parent = DataPath(segments.sublist(0, segments.length - 1));
  return apply(inputPrefix.followedBy(parent), index);
}

T? _withInteger<T>(int? value, T? Function(int value) apply) =>
    value == null ? null : apply(value);

extension LocalActionDestination on LocalAction {
  BindingReference get mutationReference => switch (this) {
    SetValueAction(:final target) ||
    InsertListItemAction(:final target) ||
    RemoveListItemAction(:final target) ||
    AppendListItemAction(:final target) ||
    PutMapEntryAction(:final target) ||
    RemoveMapEntryAction(:final target) ||
    ReplaceConcreteTypeAction(:final target) => target,
    DuplicateListItemAction(:final source) ||
    ReorderListItemAction(:final source) => BindingReference(
      bindingId: source.bindingId,
      path: DataPath(
        source.path.segments.take(source.path.segments.length - 1).toList(),
      ),
    ),
  };
}
