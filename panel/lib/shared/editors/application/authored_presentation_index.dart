import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_presentation_index.freezed.dart";

@freezed
sealed class AuthoredBindingRoot with _$AuthoredBindingRoot {
  const factory AuthoredBindingRoot.resource(skir.ResourceId resource) =
      AuthoredResourceRoot;
  const factory AuthoredBindingRoot.local(
    skir.ExpressionBindingId binding, {
    String? origin,
  }) = AuthoredLocalRoot;
  const factory AuthoredBindingRoot.collection(String sourceId) =
      AuthoredCollectionRoot;
}

@freezed
sealed class AuthoredPathStep with _$AuthoredPathStep {
  const factory AuthoredPathStep.exact(skir.PathSegment segment) =
      ExactAuthoredPathStep;
  const factory AuthoredPathStep.item() = AnyAuthoredItem;
}

/// Identifies an authored record independently of lexical binding aliases.
/// Collection templates reserve fields of their item records, while explicit
/// item paths retain the selected item identity.
@freezed
abstract class AuthoredBindingAddress with _$AuthoredBindingAddress {
  const factory AuthoredBindingAddress({
    required AuthoredBindingRoot root,
    required List<AuthoredPathStep> path,
  }) = _AuthoredBindingAddress;
  const AuthoredBindingAddress._();

  factory AuthoredBindingAddress.binding(
    skir.ExpressionBindingId id,
    PortableExpressionBinding binding,
  ) {
    final location = binding.location;
    return AuthoredBindingAddress(
      root: location == null
          ? AuthoredBindingRoot.local(id)
          : AuthoredBindingRoot.resource(location.resource),
      path: [
        for (final segment
            in location?.path.segments ?? const <skir.PathSegment>[])
          AuthoredPathStep.exact(segment),
      ],
    );
  }

  AuthoredBindingAddress append(Iterable<skir.PathSegment> segments) =>
      copyWith(
        path: [
          ...path,
          for (final segment in segments) AuthoredPathStep.exact(segment),
        ],
      );

  AuthoredBindingAddress get items =>
      copyWith(path: [...path, const AuthoredPathStep.item()]);

  /// Matches a concrete record against structural collection item addresses.
  bool matches(AuthoredBindingAddress actual) =>
      root == actual.root &&
      path.length == actual.path.length &&
      _matchesPrefix(actual);

  bool _matchesPrefix(AuthoredBindingAddress actual) {
    if (root != actual.root || path.length > actual.path.length) return false;
    for (var i = 0; i < path.length; i++) {
      final expected = path[i];
      final value = actual.path[i];
      if (expected is AnyAuthoredItem) {
        if (value is! AnyAuthoredItem &&
            (value is! ExactAuthoredPathStep ||
                value.segment is! skir.PathSegment_itemWrapper)) {
          return false;
        }
      } else if (value is AnyAuthoredItem) {
        if (expected is! ExactAuthoredPathStep ||
            expected.segment is! skir.PathSegment_itemWrapper) {
          return false;
        }
      } else if (expected != value) {
        return false;
      }
    }
    return true;
  }

  /// Projects any descendant editor to the first field below its record owner.
  String? fieldBelow(AuthoredBindingAddress record) {
    if (!record._matchesPrefix(this) || path.length <= record.path.length) {
      return null;
    }
    return switch (path[record.path.length]) {
      ExactAuthoredPathStep(
        segment: skir.PathSegment_fieldWrapper(:final value),
      ) =>
        value.name,
      _ => null,
    };
  }

  String? directFieldOf(AuthoredBindingAddress record) {
    if (root != record.root || path.length != record.path.length + 1) {
      return null;
    }
    for (var i = 0; i < record.path.length; i++) {
      final actual = record.path[i];
      if (actual is! ExactAuthoredPathStep) return null;
      switch (path[i]) {
        case ExactAuthoredPathStep(:final segment):
          if (segment != actual.segment) return null;
        case AnyAuthoredItem():
          if (actual.segment is! skir.PathSegment_itemWrapper) return null;
      }
    }
    return switch (path.last) {
      ExactAuthoredPathStep(
        segment: skir.PathSegment_fieldWrapper(:final value),
      ) =>
        value.name,
      _ => null,
    };
  }
}

extension AuthoredBindingAliases
    on Map<skir.ExpressionBindingId, AuthoredBindingAddress> {
  AuthoredBindingAddress? resolve(skir.BindingRef reference) =>
      this[reference.bindingId]?.append(reference.path.segments);
}

@freezed
abstract class AuthoredBindingUse with _$AuthoredBindingUse {
  const factory AuthoredBindingUse({required AuthoredBindingAddress address}) =
      _AuthoredBindingUse;
}

/// An immutable structural observation of one authored layout application.
/// Conditional visibility does not release an authored field to remainingFields.
@freezed
abstract class AuthoredPresentationIndex with _$AuthoredPresentationIndex {
  const factory AuthoredPresentationIndex({
    required List<AuthoredBindingUse> uses,
  }) = _AuthoredPresentationIndex;
  const AuthoredPresentationIndex._();

  /// Observes controls in their lexical scopes, including hidden decorations.
  /// [onEditableBinding] also receives unresolved and implicit edit destinations.
  /// Excluding the root prefix preserves every descendant prefix and header.
  factory AuthoredPresentationIndex.build(
    skir.PresentationNode layout,
    Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases, {
    Map<String, skir.PresentationCollectionDefinition> sources = const {},
    bool includeRootPrefix = true,
    void Function(skir.BindingRef, AuthoredBindingAddress?)? onEditableBinding,
    bool Function(
      skir.PresentationNode node,
      skir.PresentationPartElement part,
      Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases,
    )?
    onPart,
  }) => AuthoredPresentationIndex(
    uses: [
      ...layout.authoredBindingUses(
        aliases,
        sources,
        onEditableBinding,
        includeRootPrefix,
        onPart,
      ),
    ],
  );

  Set<String> fieldsOf(AuthoredBindingAddress record) => {
    for (final use in uses) ?use.address.directFieldOf(record),
  };
}

extension AuthoredPresentationBindings on skir.PresentationNode {
  Iterable<AuthoredBindingUse> authoredBindingUses(
    Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases, [
    Map<String, skir.PresentationCollectionDefinition> sources = const {},
    void Function(skir.BindingRef, AuthoredBindingAddress?)? onEditableBinding,
    bool includeRootPrefix = true,
    bool Function(
      skir.PresentationNode node,
      skir.PresentationPartElement part,
      Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases,
    )?
    onPart,
  ]) sync* {
    final control = boundControl;
    if (control != null) {
      onEditableBinding?.call(
        control.binding,
        aliases.resolve(control.binding),
      );
      if (aliases.resolve(control.binding) case final address?) {
        yield AuthoredBindingUse(address: address);
      }
    }
    final configured = configuredValueBindingId;
    for (final item in header?.items ?? const <skir.HeaderItem>[]) {
      if (item case skir.HeaderItem_reorderHandleWrapper(:final value)) {
        onEditableBinding?.call(value.source, aliases.resolve(value.source));
      }
    }
    switch (element) {
      case skir.PresentationElement_partWrapper(:final value):
        if (onPart?.call(this, value, aliases) ?? true) {
          if (value.body case final body?) {
            yield* body.authoredBindingUses(
              aliases,
              sources,
              onEditableBinding,
              true,
              onPart,
            );
          }
        }
      case skir.PresentationElement_remainingFieldsWrapper():
        final reference = skir.BindingRef(
          bindingId: configured,
          path: skir.ValuePath.defaultInstance,
        );
        onEditableBinding?.call(reference, aliases.resolve(reference));
      case skir.PresentationElement_invocationWrapper(:final value):
        final arguments = {...aliases};
        for (final argument in value.arguments) {
          final address = arguments.resolve(argument.binding);
          onEditableBinding?.call(argument.binding, address);
          arguments.remove(argument.input);
          if (address != null) arguments[argument.input] = address;
        }
        final implicit = skir.BindingRef(
          bindingId: configured,
          path: skir.ValuePath.defaultInstance,
        );
        onEditableBinding?.call(implicit, arguments.resolve(implicit));

      case skir.PresentationElement_typedFieldWrapper(:final value):
        if (aliases.resolve(value.binding) case final address?) {
          yield AuthoredBindingUse(address: address);
        }
        if (value.presentation case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_scopedBindingWrapper(:final value):
        final address = aliases.resolve(value.binding);
        final nested = {...aliases}..remove(value.scopeBindingId);
        if (address != null) nested[value.scopeBindingId] = address;
        yield* value.child.authoredBindingUses(
          nested,
          sources,
          onEditableBinding,
          true,
          onPart,
        );
      case skir.PresentationElement_recordInputWrapper(:final value):
        if (value.fieldPresentation case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_namedInputWrapper(:final value):
        if (value.payloadPresentation case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_nullableInputWrapper(:final value):
        if (value.valuePresentation case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_searchInputWrapper(:final value):
        AuthoredBindingAddress local(skir.ExpressionBindingId binding) =>
            AuthoredBindingAddress(
              root: AuthoredBindingRoot.local(binding, origin: nodeId),
              path: const [],
            );
        if (value.summary case final child?) {
          yield* child.authoredBindingUses(
            {...aliases, value.summaryBindingId: local(value.summaryBindingId)},
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
        for (final child in [value.empty, value.loading]) {
          if (child != null) {
            yield* child.authoredBindingUses(
              aliases,
              sources,
              onEditableBinding,
              true,
              onPart,
            );
          }
        }
        yield* _searchAuthoredBindingUses(
          value.provider,
          {...aliases, value.queryBindingId: local(value.queryBindingId)},
          sources,
          onEditableBinding,
          nodeId,
          onPart,
        );
      case skir.PresentationElement_polymorphicInputWrapper(:final value):
        if (aliases.resolve(value.control.binding) case final address?) {
          for (final option in value.concreteTypes) {
            if (option.presentation case final child?) {
              yield* child.authoredBindingUses(
                {...aliases, configured: address},
                sources,
                onEditableBinding,
                true,
                onPart,
              );
            }
          }
        }
      case skir.PresentationElement_polymorphicMatchWrapper(:final value):
        final address = aliases.resolve(value.binding);
        final nested = {...aliases}..remove(value.scopeBindingId);
        if (address != null) nested[value.scopeBindingId] = address;
        for (final item in value.cases) {
          yield* item.child.authoredBindingUses(
            nested,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
        if (value.fallback case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_listInputWrapper(:final value):
        if (value.itemPresentation case final child?) {
          final address =
              aliases.resolve(value.control.binding)?.items ??
              AuthoredBindingAddress(
                root: AuthoredBindingRoot.local(value.itemBindingId),
                path: const [],
              );
          yield* child.authoredBindingUses(
            {...aliases, value.itemBindingId: address},
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_setInputWrapper(:final value):
        if (value.itemPresentation case final child?) {
          final address =
              aliases.resolve(value.control.binding)?.items ??
              AuthoredBindingAddress(
                root: AuthoredBindingRoot.local(value.itemBindingId),
                path: const [],
              );
          yield* child.authoredBindingUses(
            {...aliases, value.itemBindingId: address},
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_mapInputWrapper(:final value):
        final address = aliases.resolve(value.control.binding)?.items;
        if (value.keyPresentation case final child?) {
          yield* child.authoredBindingUses(
            {
              ...aliases,
              value.keyBindingId:
                  address?.append([skir.PathSegment.mapKey]) ??
                  AuthoredBindingAddress(
                    root: AuthoredBindingRoot.local(value.keyBindingId),
                    path: const [],
                  ),
            },
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
        if (value.valuePresentation case final child?) {
          yield* child.authoredBindingUses(
            {
              ...aliases,
              value.valueBindingId:
                  address?.append([skir.PathSegment.mapValue]) ??
                  AuthoredBindingAddress(
                    root: AuthoredBindingRoot.local(value.valueBindingId),
                    path: const [],
                  ),
            },
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_repeatedWrapper(:final value):
        final source = switch (value.source) {
          skir.ExpressionNode_inputWrapper(:final value) => aliases.resolve(
            skir.BindingRef(bindingId: value.binding, path: value.path),
          ),
          _ => null,
        };
        final address =
            source?.items ??
            AuthoredBindingAddress(
              root: AuthoredBindingRoot.local(
                value.itemBindingId,
                origin: nodeId,
              ),
              path: const [],
            );
        yield* value.presentation.item.authoredBindingUses(
          {...aliases, value.itemBindingId: address},
          sources,
          onEditableBinding,
          true,
          onPart,
        );
        if (source != null) {
          yield* value.presentation.item.authoredBindingUses(
            {
              ...aliases,
              value.itemBindingId: address.append([skir.PathSegment.mapValue]),
            },
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
        if (value.presentation.empty case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
        if (value.presentation.separator case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_collectionLookupWrapper(:final value):
        final definition = sources[value.sourceId];
        final address = AuthoredBindingAddress(
          root: AuthoredBindingRoot.collection(value.sourceId),
          path: const [AuthoredPathStep.item()],
        );
        yield* value.found.authoredBindingUses(
          {
            ...aliases,
            if (definition != null) definition.rowBindingId: address,
          },
          sources,
          onEditableBinding,
          true,
          onPart,
        );
        yield* value.missing.authoredBindingUses(
          aliases,
          sources,
          onEditableBinding,
          true,
          onPart,
        );
        if (value.loading case final child?) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
      case skir.PresentationElement_collectionGraphWrapper(:final value):
        final definition = sources[value.sourceId];
        final source = AuthoredBindingAddress(
          root: AuthoredBindingRoot.collection(value.sourceId),
          path: const [],
        );
        final address = source.items;
        final nested = {
          ...aliases,
          if (definition != null) definition.rowBindingId: address,
          value.childrenBindingId: source,
        };
        yield* value.node.authoredBindingUses(
          nested,
          sources,
          onEditableBinding,
          true,
          onPart,
        );
        yield* value.rootSequence.item.authoredBindingUses(
          nested,
          sources,
          onEditableBinding,
          true,
          onPart,
        );
        yield* value.children.item.authoredBindingUses(
          {...nested, value.childBindingId: address},
          sources,
          onEditableBinding,
          true,
          onPart,
        );
        for (final child in [
          value.rootSequence.empty,
          value.rootSequence.separator,
          value.children.empty,
          value.children.separator,
        ]) {
          if (child != null) {
            yield* child.authoredBindingUses(
              aliases,
              sources,
              onEditableBinding,
              true,
              onPart,
            );
          }
        }
      default:
        for (final child in presentationBodyNodes) {
          yield* child.authoredBindingUses(
            aliases,
            sources,
            onEditableBinding,
            true,
            onPart,
          );
        }
    }
    for (final child in presentationDecorationNodes(
      includeControlPrefix: includeRootPrefix,
    )) {
      yield* child.authoredBindingUses(
        aliases,
        sources,
        onEditableBinding,
        true,
        onPart,
      );
    }
  }
}

Iterable<AuthoredBindingUse> _searchAuthoredBindingUses(
  skir.SearchProvider provider,
  Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases,
  Map<String, skir.PresentationCollectionDefinition> sources,
  void Function(skir.BindingRef, AuthoredBindingAddress?)? onEditableBinding,
  String origin,
  bool Function(
    skir.PresentationNode node,
    skir.PresentationPartElement part,
    Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases,
  )?
  onPart,
) sync* {
  AuthoredBindingAddress foreign(skir.ExpressionBindingId binding) =>
      AuthoredBindingAddress(
        root: AuthoredBindingRoot.local(binding, origin: origin),
        path: const [],
      );
  Iterable<AuthoredBindingUse> result(
    skir.SearchResultMapping mapping,
    Map<skir.ExpressionBindingId, AuthoredBindingAddress> environment,
  ) sync* {
    final nested = {
      ...environment,
      mapping.bindingId: foreign(mapping.bindingId),
    };
    yield* mapping.presentation.authoredBindingUses(
      nested,
      sources,
      onEditableBinding,
      true,
      onPart,
    );
  }

  switch (provider) {
    case skir.SearchProvider_staticValuesWrapper(:final value):
      yield* result(value.result, aliases);
    case skir.SearchProvider_collectionWrapper(:final value):
      yield* result(value.result, aliases);
    case skir.SearchProvider_realmCallbackWrapper(:final value):
      yield* result(value.result, aliases);
    case skir.SearchProvider_httpJsonWrapper(:final value):
      yield* result(value.result, {
        ...aliases,
        for (final context in value.contextBindings)
          context.bindingId: foreign(context.bindingId),
      });
    case skir.SearchProvider_gateWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_debounceWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_cacheWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_rankWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_limitWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_distinctWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_historyWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_sectionWrapper(:final value):
      yield* _searchAuthoredBindingUses(
        value.child,
        aliases,
        sources,
        onEditableBinding,
        origin,
        onPart,
      );
    case skir.SearchProvider_mergeWrapper(:final value):
      for (final child in value.children) {
        yield* _searchAuthoredBindingUses(
          child,
          aliases,
          sources,
          onEditableBinding,
          origin,
          onPart,
        );
      }
    default:
      break;
  }
}
