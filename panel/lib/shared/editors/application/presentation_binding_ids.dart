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
final presentationSelectionCountBindingId = skir.ExpressionBindingId(
  value: "presentation.context.selection_count",
);
