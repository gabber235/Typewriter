/// Declarative presentation and expression contracts for the editor panel.
///
/// This barrel exposes the shared model used by catalog producers, protocol
/// codecs, renderers, and action hosts. Presentation trees describe controls
/// and layout, bindings identify editor owned values, and expressions provide
/// derived values without storing UI state in the domain model.
library;

export "action.dart";
export "action_executor.dart";
export "action_map_executor.dart";
export "action_mutation.dart";
export "binding.dart";
export "collection_expression_authoring.dart";
export "default_presentation.dart";
export "expression.dart";
export "expression_authoring.dart";
export "expression_evaluator.dart";
export "expression_operations.dart";
export "identifier_input_formats.dart";
export "presentation_collection.dart";
export "presentation_element.dart";
export "presentation_expression_substitution.dart";
export "presentation_header.dart";
export "presentation_header_resolution.dart";
export "presentation_localizer.dart";
export "presentation_node.dart";
export "presentation_role_resolver.dart";
export "presentation_substitution.dart";
export "presentation_target.dart";
export "presentation_validation.dart";
export "text_input_format.dart";
