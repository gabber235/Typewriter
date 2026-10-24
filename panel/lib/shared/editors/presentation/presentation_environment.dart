import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Host context shared by all presentations in this subtree. A nested
/// environment adds to the enclosing one.
final class PresentationEnvironment extends InheritedWidget {
  const PresentationEnvironment({
    required this.host,
    required super.child,
    super.key,
  });

  final HostContext host;

  static PresentationEnvironment? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PresentationEnvironment>();

  /// The host context of the nearest environment, or [HostContext.empty].
  static HostContext hostOf(BuildContext context) =>
      maybeOf(context)?.host ?? HostContext.empty;

  @override
  bool updateShouldNotify(PresentationEnvironment oldWidget) =>
      host != oldWidget.host;
}

extension PortablePresentationBindingEnvironment
    on Map<skir.ExpressionBindingId, PortableExpressionBinding> {
  Map<skir.ExpressionBindingId, PortableExpressionBinding>
  withPresentationEnvironment(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> environment,
  ) {
    final collisions = keys.toSet().intersection(environment.keys.toSet());
    if (collisions.isNotEmpty) {
      throw StateError("Presentation input IDs collide: $collisions");
    }
    if (environment.values.any((binding) => binding.location != null)) {
      throw StateError("Presentation environment inputs must be read only");
    }
    return Map.unmodifiable({...this, ...environment});
  }
}

extension PortableCallerBindings
    on Map<skir.ExpressionBindingId, PortableExpressionBinding> {
  Map<skir.ExpressionBindingId, PortableExpressionBinding> withCallerInputs(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> supplied,
  ) {
    final result = {...this};
    for (final entry in supplied.entries) {
      if (entry.value.location != null) {
        throw StateError("Caller input must be read only");
      }
      final previous = result[entry.key];
      if (previous != null && !identical(previous, entry.value)) {
        throw StateError("Caller input has conflicting suppliers");
      }
      result[entry.key] = entry.value;
    }
    return Map.unmodifiable(result);
  }
}

extension PortableContextImports
    on Map<skir.ExpressionBindingId, PortableExpressionBinding> {
  /// Imports require exact declared schemas and read only observations. Host
  /// inputs not already bound take their value from [host]. Missing inputs
  /// become typed unfilled values, preserving unavailable data separately
  /// from malformed or conflicting input.
  Map<skir.ExpressionBindingId, PortableExpressionBinding> withContextImports({
    required CheckedEditorCatalog catalog,
    required Iterable<skir.PresentationContextInput> imports,
    HostContext host = HostContext.empty,
  }) {
    final result = {...this};
    for (final input in imports) {
      if (input.source case skir.PresentationContextSource_hostWrapper(
        :final value,
      )) {
        if (HostContext.valueType(value) != input.valueType) {
          throw const FormatException("Host input has an incompatible type");
        }
        if (!result.containsKey(input.bindingId)) {
          if (host.bindingFor(value) case final binding?) {
            result[input.bindingId] = binding;
          }
        }
      }
      final supplied = result[input.bindingId];
      if (supplied == null) {
        result[input.bindingId] = PortableExpressionBinding(
          schema: CompletePortablePresentationBinding(input.valueType),
          value: skir.DataValue.unfilled,
        );
        continue;
      }
      if (supplied.location != null ||
          supplied.schema !=
              CompletePortablePresentationBinding(input.valueType)) {
        throw const FormatException("Caller input has an incompatible binding");
      }
      final inspection = catalog.inspectPortableValue(
        input.valueType,
        supplied.value,
      );
      if (inspection.structuralProblems.isNotEmpty) {
        throw const FormatException("Caller input has malformed data");
      }
    }
    return Map.unmodifiable(result);
  }
}

Map<skir.ExpressionBindingId, PortableExpressionBinding>
normalizePresentationBindings({
  required CheckedEditorCatalog catalog,
  required Map<skir.ExpressionBindingId, PortablePresentationBinding> document,
  required Map<skir.ExpressionBindingId, PortableExpressionBinding> surface,
  required Iterable<skir.PresentationContextInput> imports,
  HostContext host = HostContext.empty,
}) =>
    {
          for (final entry in document.entries)
            entry.key: PortableExpressionBinding(
              value: entry.value.value,
              location: entry.value.location,
              schema: entry.value.schema,
            ),
        }
        .withPresentationEnvironment(surface)
        .withContextImports(catalog: catalog, imports: imports, host: host);
