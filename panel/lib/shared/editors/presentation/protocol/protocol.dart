/// Presentation rendering is the panel side of the editor protocol.
///
/// The protocol turns serialized presentation nodes into widgets. A
/// [PresentationRenderScope] carries expression evaluation, binding access,
/// mutation routing, action execution, and transient expansion state through
/// the tree. Renderers stay stateless with respect to resource drafts. Draft
/// ownership remains with the [EditorSource] supplied by the surrounding
/// editor surface.
library;

export "action_canonicalization.dart";
export "bound_control_shell.dart";
export "bound_value_renderer.dart";
export "composite_input_renderer.dart";
export "content_renderer.dart";
export "data_renderer.dart";
export "editor_field_interaction.dart";
export "field_diagnostics.dart";
export "header_combination.dart";
export "header_renderer.dart";
export "input_renderer.dart";
export "interaction_renderer.dart";
export "layout_renderer.dart";
export "node_renderer.dart";
export "presentation_diagnostic.dart";
export "presentation_surface.dart";
export "protocol_renderer.dart";
export "render_scope.dart";
export "renderers/renderers.dart";
export "scalar_input_renderer.dart";
export "simple_input_renderer.dart";
export "text_input_formatters.dart";
