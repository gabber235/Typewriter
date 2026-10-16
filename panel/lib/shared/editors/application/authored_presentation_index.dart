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
  const factory AuthoredBindingUse({
    required AuthoredBindingAddress address,
    skir.PresentationId? selectedPresentation,
  }) = _AuthoredBindingUse;
}

/// An immutable structural observation of one authored layout application.
/// Conditional visibility does not release an authored field to remainingFields.
@freezed
abstract class AuthoredPresentationIndex with _$AuthoredPresentationIndex {
  const factory AuthoredPresentationIndex({
    required List<AuthoredBindingUse> uses,
  }) = _AuthoredPresentationIndex;
  const AuthoredPresentationIndex._();

  factory AuthoredPresentationIndex.build(
    skir.PresentationNode layout,
    Map<skir.ExpressionBindingId, AuthoredBindingAddress> aliases, {
    Map<String, skir.PresentationCollectionDefinition> sources = const {},
    Iterable<skir.PresentationNode> additionalLayouts = const [],
  }) => AuthoredPresentationIndex(
    uses: [
      ...layout.authoredBindingUses(aliases, sources),
      for (final additional in additionalLayouts)
        ...additional.authoredBindingUses(aliases, sources),
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
  ]) sync* {
    final control = boundControl;
    final selected = switch (element) {
      skir.PresentationElement_defaultPresentationWrapper(:final value) =>
        value.presentationId,
      _ => null,
    };
    if (control != null) {
      if (aliases.resolve(control.binding) case final address?) {
        yield AuthoredBindingUse(
          address: address,
          selectedPresentation: selected,
        );
      }
    }
    final configured = skir.ExpressionBindingId(value: "configured_value");
    switch (element) {
      case skir.PresentationElement_typedFieldWrapper(:final value):
        if (aliases.resolve(value.binding) case final address?) {
          yield AuthoredBindingUse(address: address);
        }
        if (value.presentation case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
      case skir.PresentationElement_scopedBindingWrapper(:final value):
        if (aliases.resolve(value.binding) case final address?) {
          yield* value.child.authoredBindingUses({
            ...aliases,
            value.scopeBindingId: address,
          }, sources);
        }
      case skir.PresentationElement_recordInputWrapper(:final value):
        if (value.fieldPresentation case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
      case skir.PresentationElement_namedInputWrapper(:final value):
        if (value.payloadPresentation case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
      case skir.PresentationElement_nullableInputWrapper(:final value):
        if (value.valuePresentation case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
      case skir.PresentationElement_polymorphicInputWrapper(:final value):
        if (aliases.resolve(value.control.binding) case final address?) {
          for (final option in value.concreteTypes) {
            if (option.presentation case final child?) {
              yield* child.authoredBindingUses({
                ...aliases,
                configured: address,
              }, sources);
            }
          }
        }
      case skir.PresentationElement_polymorphicMatchWrapper(:final value):
        if (aliases.resolve(value.binding) case final address?) {
          final nested = {...aliases, value.scopeBindingId: address};
          for (final item in value.cases) {
            yield* item.child.authoredBindingUses(nested, sources);
          }
        }
        if (value.fallback case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
      case skir.PresentationElement_listInputWrapper(:final value):
        if (value.itemPresentation case final child?) {
          final address =
              aliases.resolve(value.control.binding)?.items ??
              AuthoredBindingAddress(
                root: AuthoredBindingRoot.local(value.itemBindingId),
                path: const [],
              );
          yield* child.authoredBindingUses({
            ...aliases,
            value.itemBindingId: address,
          }, sources);
        }
      case skir.PresentationElement_setInputWrapper(:final value):
        if (value.itemPresentation case final child?) {
          final address =
              aliases.resolve(value.control.binding)?.items ??
              AuthoredBindingAddress(
                root: AuthoredBindingRoot.local(value.itemBindingId),
                path: const [],
              );
          yield* child.authoredBindingUses({
            ...aliases,
            value.itemBindingId: address,
          }, sources);
        }
      case skir.PresentationElement_mapInputWrapper(:final value):
        final address = aliases.resolve(value.control.binding)?.items;
        if (value.keyPresentation case final child?) {
          yield* child.authoredBindingUses({
            ...aliases,
            value.keyBindingId:
                address?.append([skir.PathSegment.mapKey]) ??
                AuthoredBindingAddress(
                  root: AuthoredBindingRoot.local(value.keyBindingId),
                  path: const [],
                ),
          }, sources);
        }
        if (value.valuePresentation case final child?) {
          yield* child.authoredBindingUses({
            ...aliases,
            value.valueBindingId:
                address?.append([skir.PathSegment.mapValue]) ??
                AuthoredBindingAddress(
                  root: AuthoredBindingRoot.local(value.valueBindingId),
                  path: const [],
                ),
          }, sources);
        }
      case skir.PresentationElement_repeatedWrapper(:final value):
        final source = switch (value.source) {
          skir.ExpressionNode_readWrapper(:final value) => aliases.resolve(
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
        yield* value.presentation.item.authoredBindingUses({
          ...aliases,
          value.itemBindingId: address,
        }, sources);
        if (source != null) {
          yield* value.presentation.item.authoredBindingUses({
            ...aliases,
            value.itemBindingId: address.append([skir.PathSegment.mapValue]),
          }, sources);
        }
        if (value.presentation.empty case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
        if (value.presentation.separator case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
        }
      case skir.PresentationElement_collectionLookupWrapper(:final value):
        final definition = sources[value.sourceId];
        final address = AuthoredBindingAddress(
          root: AuthoredBindingRoot.collection(value.sourceId),
          path: const [AuthoredPathStep.item()],
        );
        yield* value.found.authoredBindingUses({
          ...aliases,
          if (definition != null) definition.rowBindingId: address,
        }, sources);
        yield* value.missing.authoredBindingUses(aliases, sources);
        if (value.loading case final child?) {
          yield* child.authoredBindingUses(aliases, sources);
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
        yield* value.node.authoredBindingUses(nested, sources);
        yield* value.rootSequence.item.authoredBindingUses(nested, sources);
        yield* value.children.item.authoredBindingUses({
          ...nested,
          value.childBindingId: address,
        }, sources);
        for (final child in [
          value.rootSequence.empty,
          value.rootSequence.separator,
          value.children.empty,
          value.children.separator,
        ]) {
          if (child != null) yield* child.authoredBindingUses(aliases, sources);
        }
      default:
        for (final child in nestedPresentationNodes.where(
          (child) => child != control?.prefix,
        )) {
          yield* child.authoredBindingUses(aliases, sources);
        }
    }
    if (control?.prefix case final prefix?) {
      yield* prefix.authoredBindingUses(aliases, sources);
    }
  }
}
