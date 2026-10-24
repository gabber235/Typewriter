import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

final configuredValueBindingId = skir.ExpressionBindingId(
  value: "configured_value",
);

final presentationSubjectIdentifierBindingId = skir.ExpressionBindingId(
  value: "presentation.subject.identifier",
);

/// The evaluated display of the presented resource, bound wherever the
/// subject identifier is. Generated resource presentation scopes read it as
/// `appearance`.
final presentationSubjectAppearanceBindingId = skir.ExpressionBindingId(
  value: "presentation.subject.appearance",
);

/// The host selection count, as presentations built in the panel declare it.
/// The binding name is local to those presentations; hosts fill it through
/// the declared source.
final panelSelectionCountInput = skir.PresentationContextInput(
  bindingId: skir.ExpressionBindingId(value: "context:panel.selection_count"),
  source: skir.PresentationContextSource.wrapHost(
    skir.HostContextInput.selectionCount,
  ),
  valueType: skir.TypeUse.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
  ),
);
