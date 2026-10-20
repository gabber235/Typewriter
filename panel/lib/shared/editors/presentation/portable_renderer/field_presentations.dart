part of "../portable_presentation_renderer.dart";

/// Effective metadata for one control, shared by its frame and native input.
@freezed
abstract class ResolvedFieldAssociation with _$ResolvedFieldAssociation {
  const factory ResolvedFieldAssociation({
    String? label,
    String? description,
    String? semanticLabel,
    ScopedControlPrefix? prefix,
  }) = _ResolvedFieldAssociation;
  const ResolvedFieldAssociation._();

  factory ResolvedFieldAssociation.fromControl(
    skir.BoundControl control,
    PortablePresentationScope scope,
  ) {
    final label = _controlString(control.label, scope);
    return ResolvedFieldAssociation(
      label: label,
      description: _controlString(control.description, scope),
      semanticLabel: control.semanticLabel == null
          ? label
          : _controlString(control.semanticLabel, scope),
      prefix: control.prefix == null
          ? null
          : ScopedControlPrefix(node: control.prefix!, scope: scope),
    );
  }

  ResolvedFieldAssociation withFallbackLabel(String? fallback) =>
      label != null || fallback == null
      ? this
      : copyWith(label: fallback, semanticLabel: semanticLabel ?? fallback);
}

/// A prefix keeps the bindings and material in which it was authored.
@freezed
abstract class ScopedControlPrefix with _$ScopedControlPrefix {
  const factory ScopedControlPrefix({
    required skir.PresentationNode node,
    required PortablePresentationScope scope,
  }) = _ScopedControlPrefix;
  const ScopedControlPrefix._();

  Widget render(PortablePresentationScope caller) =>
      PortablePresentationNodeRenderer(
        node: node,
        scope: scope.copyWith(
          enabled: scope.enabled && caller.enabled,
          readOnly: scope.readOnly || caller.readOnly,
          activePresentations: {
            ...scope.activePresentations,
            ...caller.activePresentations,
          },
          activeFieldPresentations: {
            ...scope.activeFieldPresentations,
            ...caller.activeFieldPresentations,
          },
          activeParts: {...scope.activeParts, ...caller.activeParts},
          activeInspectorLayouts: {
            ...scope.activeInspectorLayouts,
            ...caller.activeInspectorLayouts,
          },
        ),
      );
}

@freezed
abstract class PortableRecordFieldOwner with _$PortableRecordFieldOwner {
  const factory PortableRecordFieldOwner({
    required skir.TypeSelection type,
    required String field,
    required AuthoredBindingAddress address,
    required PortablePresentationScope scope,
  }) = _PortableRecordFieldOwner;
}

@freezed
abstract class ActiveFieldPresentation with _$ActiveFieldPresentation {
  const factory ActiveFieldPresentation({
    required EditorFieldPresentationIdentity identity,
    required AuthoredBindingAddress owner,
  }) = _ActiveFieldPresentation;
}

extension PortableFieldPresentationScope on PortablePresentationScope {
  ResolvedFieldAssociation associationFor(skir.BoundControl control) =>
      identical(associatedControl, control) && fieldAssociation != null
      ? fieldAssociation!
      : ResolvedFieldAssociation.fromControl(control, this);

  /// Resolves the containing record before a default rebinds to its field.
  PortableRecordFieldOwner? recordOwning(skir.BindingRef reference) {
    final path = reference.path.segments.toList(growable: false);
    if (path.isEmpty) return null;
    final field = switch (path.last) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (field == null) return null;
    final record = skir.BindingRef(
      bindingId: reference.bindingId,
      path: skir.ValuePath(segments: path.take(path.length - 1)),
    );
    final owner = withConfiguredValue(record);
    final type = owner?.configuredSelection;
    final address = owner?.authoredAliases[configuredValueBindingId];
    if (owner == null || type == null || address == null) return null;
    final checked = owner.catalog;
    if (checked == null ||
        !checked
            .fields(type)
            .any((candidate) => candidate.template.key == field)) {
      return null;
    }
    return PortableRecordFieldOwner(
      type: type,
      field: field,
      address: address,
      scope: owner,
    );
  }

  skir.TypeSelection? get configuredSelection {
    final configured = bindings[configuredValueBindingId];
    final actual = configured?.value.authoredActualType;
    if (actual != null) return skir.TypeSelection.wrapComplete(actual);
    switch (configured?.schema) {
      case PartialPortablePresentationBinding(:final selection):
        return selection;
      case CompletePortablePresentationBinding(:final use):
        if (use.withoutNullableWrappers case skir.TypeUse_namedWrapper(
          :final value,
        )) {
          return skir.TypeSelection.wrapComplete(value);
        }
      case null:
        break;
    }
    final projectionHost = switch (host) {
      final PortableCollectionProjectionHost value => value,
      _ => null,
    };
    return resource == null || projectionHost == null
        ? null
        : projectionHost
              .projectResource(resource!, context: invocation)
              ?.configuration;
  }

  PortablePresentationScope withAuthoredFragment(
    skir.PresentationNode fragment, {
    bool includeRootPrefix = true,
  }) {
    final aliases = {
      for (final entry in bindings.entries)
        entry.key: entry.value.location == null
            ? authoredAliases[entry.key] ??
                  AuthoredBindingAddress.binding(entry.key, entry.value)
            : AuthoredBindingAddress.binding(entry.key, entry.value),
    };
    final added = AuthoredPresentationIndex.build(
      fragment,
      aliases,
      includeRootPrefix: includeRootPrefix,
      sources: {
        for (final source
            in material?.dependencies.collections ??
                const <skir.PresentationCollectionDefinition>[])
          source.sourceId: source,
      },
    );
    return copyWith(
      authoredAliases: aliases,
      authoredIndex: AuthoredPresentationIndex(
        uses: [...?authoredIndex?.uses, ...added.uses],
      ),
      independentAuthoredIndex: AuthoredPresentationIndex(
        uses: [...?independentAuthoredIndex?.uses, ...added.uses],
      ),
    );
  }
}

ResolvedFieldAssociation _resolveFieldAssociation({
  required skir.BoundControl inherited,
  required PortablePresentationScope inheritedScope,
  required skir.BoundControl local,
  required PortablePresentationScope localScope,
  required String fallbackLabel,
}) {
  final inheritedValues = inheritedScope.associationFor(inherited);
  final localValues = localScope.associationFor(local);
  final label = local.label != null ? localValues.label : inheritedValues.label;
  final semanticLabel = local.semanticLabel != null
      ? localValues.semanticLabel
      : inherited.semanticLabel != null
      ? inheritedValues.semanticLabel
      : label;
  return ResolvedFieldAssociation(
    label: label,
    description: local.description != null
        ? localValues.description
        : inheritedValues.description,
    semanticLabel: semanticLabel,
    prefix: local.prefix != null ? localValues.prefix : inheritedValues.prefix,
  ).withFallbackLabel(fallbackLabel);
}
