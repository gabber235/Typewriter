import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Read only surface observations shared by all presentations in this subtree.
final class PresentationEnvironment extends InheritedWidget {
  PresentationEnvironment({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required super.child,
    super.key,
  }) : bindings = Map.unmodifiable(bindings);

  final Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings;

  static PresentationEnvironment? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PresentationEnvironment>();

  @override
  bool updateShouldNotify(PresentationEnvironment oldWidget) =>
      !mapEquals(bindings, oldWidget.bindings);
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
