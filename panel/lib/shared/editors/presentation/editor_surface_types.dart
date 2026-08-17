part of "editor_surface.dart";

@freezed
abstract class _EditorSurfaceDefinitionResolution
    with _$EditorSurfaceDefinitionResolution {
  const factory _EditorSurfaceDefinitionResolution({
    required EditorDocument document,
    required DataPath path,
    required TypeRegistry? registryOverride,
    required TypeResult<_EditorSurfaceDefinition> result,
  }) = _EditorSurfaceDefinitionResolutionData;

  const _EditorSurfaceDefinitionResolution._();

  factory _EditorSurfaceDefinitionResolution.resolve({
    required EditorDocument document,
    required DataPath path,
    required TypeRegistry? registryOverride,
  }) {
    final registry = registryOverride ?? TypeRegistry(document.typeCatalog);
    final typeResult = document.rootType.resolvePath(path, registry: registry);
    if (typeResult case TypeFailure(:final diagnostics)) {
      return _EditorSurfaceDefinitionResolution(
        document: document,
        path: path,
        registryOverride: registryOverride,
        result: TypeResult.failure(diagnostics),
      );
    }

    final declaredType = typeResult.valueOrNull!;
    final type = _representation(registry, declaredType);
    final selectedPresentation = _resolvePresentation(
      document,
      registry,
      declaredType,
      null,
    );
    final rootPresentation = path == DataPath.root
        ? document.rootPresentation
        : null;
    final bindingType = _bindingType(
      registry,
      declaredType,
      type,
      rootPresentation ?? selectedPresentation?.root,
    );
    final presentation =
        rootPresentation ??
        selectedPresentation?.root ??
        bindingType.generateDefaultPresentation();
    final definition = _EditorSurfaceDefinition(
      document: document,
      registry: registry,
      type: type,
      bindingType: bindingType,
      selectedPresentation: selectedPresentation,
      presentation: presentation,
    );
    return _EditorSurfaceDefinitionResolution(
      document: document,
      path: path,
      registryOverride: registryOverride,
      result: TypeResult.success(definition),
    );
  }

  bool matches(
    EditorDocument document,
    DataPath path,
    TypeRegistry? registryOverride,
  ) {
    return identical(this.document, document) &&
        this.path == path &&
        identical(this.registryOverride, registryOverride);
  }
}

@freezed
abstract class _EditorSurfaceDefinition with _$EditorSurfaceDefinition {
  const factory _EditorSurfaceDefinition({
    required EditorDocument document,
    required TypeRegistry registry,
    required TypeExpression type,
    required TypeExpression bindingType,
    required ResolvedPresentationDefinition? selectedPresentation,
    required PresentationNode presentation,
  }) = _EditorSurfaceDefinitionData;

  const _EditorSurfaceDefinition._();

  ResolvedPresentationDefinition? resolvePresentation(
    TypeExpression type,
    PresentationId? requested,
  ) {
    return _resolvePresentation(document, registry, type, requested);
  }
}

TypeExpression _representation(TypeRegistry registry, TypeExpression type) {
  return switch (type) {
    NamedType() => registry.resolve(type).valueOrNull?.representation ?? type,
    _ => type,
  };
}

TypeExpression _bindingType(
  TypeRegistry registry,
  TypeExpression declaredType,
  TypeExpression representation,
  PresentationNode? presentation,
) {
  if (declaredType is! NamedType) return representation;
  if (!_requiresNominalBinding(presentation)) return representation;
  var nominal = declaredType;
  final visited = <ResolvedTypeRef>{};
  while (visited.add(nominal.reference)) {
    final next = registry.resolve(nominal).valueOrNull?.representation;
    if (next is NamedType) {
      nominal = next;
      continue;
    }
    if (next is RecordType || next is ListType || next is MapType) {
      return next!;
    }
    return nominal;
  }
  return representation;
}

bool _requiresNominalBinding(PresentationNode? presentation) {
  if (presentation == null) return false;
  final element = presentation.element;
  final binding = switch (element) {
    ColorInputElement(:final control) ||
    SearchInputElement(:final control) ||
    NamedInputElement(:final control) ||
    PolymorphicInputElement(:final control) => control.binding,
    _ => null,
  };
  if (binding == const BindingReference(bindingId: BindingId(0))) return true;
  return _presentationChildren(element).any(_requiresNominalBinding);
}

Iterable<PresentationNode> _presentationChildren(PresentationElement element) {
  return [
    ?_controlPrefix(element),
    ...switch (element) {
      ChildrenLayoutElement(:final children) ||
      GridElement(:final children) ||
      StackElement(:final children) => children,
      SingleChildLayoutElement(:final child) => [child],
      TypedFieldElement(:final presentation) => [?presentation],
      ConditionalElement(:final whenTrue, :final whenFalse) => [
        whenTrue,
        ?whenFalse,
      ],
      RepeatedElement(:final presentation) => presentation.nodes,
      ScopedBindingElement(:final child) => [child],
      CollectionLookupElement(:final found, :final missing, :final loading) => [
        found,
        missing,
        ?loading,
      ],
      CollectionGraphElement(
        :final node,
        :final rootSequence,
        :final children,
      ) =>
        [node, ...rootSequence.nodes, ...children.nodes],
      SearchInputElement(:final summary) => [?summary],
      ListInputElement(:final itemPresentation) => [?itemPresentation],
      MapInputElement(:final keyPresentation, :final valuePresentation) => [
        ?keyPresentation,
        ?valuePresentation,
      ],
      RecordInputElement(:final fieldPresentation) => [?fieldPresentation],
      PolymorphicInputElement(:final concreteTypes) => [
        for (final type in concreteTypes) ?type.presentation,
      ],
      TabsElement(:final tabs) => [for (final tab in tabs) tab.child],
      TooltipElement(:final child) => [child],
      _ => const [],
    },
  ];
}

PresentationNode? _controlPrefix(PresentationElement element) {
  return switch (element) {
    TextInputElement(:final control) ||
    NumericInputElement(:final control) ||
    ToggleInputElement(:final control) ||
    SelectInputElement(:final control) ||
    SliderInputElement(:final control) ||
    SimpleInputElement(:final control) ||
    SearchInputElement(:final control) ||
    ListInputElement(:final control) ||
    MapInputElement(:final control) ||
    RecordInputElement(:final control) ||
    PolymorphicInputElement(:final control) => control.prefix,
    _ => null,
  };
}

extension on SequencePresentation {
  Iterable<PresentationNode> get nodes => [item, ?empty, ?separator];
}

DataPath? _localActionMutationPath(
  EditorAction action,
  Map<BindingId, BindingReference> aliases,
) {
  if (action is! LocalEditorAction) return null;
  final local = action.canonicalizedWith(aliases).action;
  final reference = switch (local) {
    SetValueAction(:final target) ||
    InsertListItemAction(:final target) ||
    RemoveListItemAction(:final target) ||
    AppendListItemAction(:final target) ||
    PutMapEntryAction(:final target) ||
    RemoveMapEntryAction(:final target) ||
    ReplaceConcreteTypeAction(:final target) => target,
    DuplicateListItemAction(:final source) ||
    ReorderListItemAction(:final source) => _parentReference(source),
  };
  if (reference.bindingId != const BindingId(0)) return null;
  return reference.path;
}

BindingReference _parentReference(BindingReference reference) {
  final segments = reference.path.segments;
  if (segments.isEmpty) return reference;
  return BindingReference(
    bindingId: reference.bindingId,
    path: DataPath(segments.sublist(0, segments.length - 1)),
  );
}

ResolvedPresentationDefinition? _resolvePresentation(
  EditorDocument document,
  TypeRegistry registry,
  TypeExpression type,
  PresentationId? requested,
) {
  final selected = requested ?? _defaultPresentationId(registry, type);
  if (selected == null) return null;
  final candidates = [
    ...builtinPresentationDefinitions(),
    ...document.presentations,
  ];
  final definition = candidates
      .where((candidate) => candidate.id == selected)
      .firstOrNull;
  if (definition == null) return null;
  final substitutions = definition.target.inferPresentationSubstitutions(type);
  if (substitutions == null) return null;
  return ResolvedPresentationDefinition(
    id: selected,
    root: definition.root.substitute(substitutions),
  );
}

PresentationId? _defaultPresentationId(
  TypeRegistry registry,
  TypeExpression type,
) {
  return switch (type) {
    NamedType(:final reference) =>
      registry.definition(reference)?.defaultPresentationId,
    _ => null,
  };
}
