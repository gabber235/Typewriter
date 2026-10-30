import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Resolving links of an authoring edit the way choosing a link target does.
extension SingleLinkResolution on AuthoringEdit {
  /// Resolves the link from [field] of [source] to [target] through the one
  /// plan that field offers, against the edit's own catalog.
  ResolvedReference resolveSingleLink(
    skir.ResourceId source,
    String field,
    skir.ResourceId target,
  ) {
    final plan = (linkPlans(
      catalog: catalog!,
      source: skir.ValueLocation(
        resource: source,
        path: editorRootPath.field(field),
      ),
    ) as PortableLinkPlanReady).plans.single;
    return resolveReference(
      catalog: catalog!,
      plan: plan,
      target: plan.targets.singleWhere((choice) => choice.resource == target),
    );
  }
}
