/// A quest form whose fields the diagnostic stories report problems on.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";

/// The binding of the quest the diagnostic stories edit.
final storyQuest = skir.ExpressionBindingId(value: "quest");

/// The quest itself, as a diagnostic target.
final storyQuestTarget = PortableDiagnosticTarget.binding(
  skir.BindingRef(bindingId: storyQuest, path: editorRootPath),
);

/// The quest field named [name], as a diagnostic target.
PortableDiagnosticTarget storyQuestField(String name) =>
    PortableDiagnosticTarget.binding(
      skir.BindingRef(bindingId: storyQuest, path: editorRootPath.field(name)),
    );

/// A problem [message] of [severity] on the quest field named [field], or
/// on nothing in particular when [field] is null.
PortablePresentationDiagnostic storyDiagnostic(
  String message, {
  skir.DiagnosticSeverity severity = skir.DiagnosticSeverity.error,
  String? field,
}) => PortablePresentationDiagnostic(
  code: "story_${field ?? "general"}_${severity.kind.name}",
  message: message,
  severity: severity,
  targets: field == null ? const [] : [storyQuestField(field)],
);

/// The severities a diagnostic story knob offers, by the name it shows.
const storySeverities = {
  "Information": skir.DiagnosticSeverity.information,
  "Warning": skir.DiagnosticSeverity.warning,
  "Error": skir.DiagnosticSeverity.error,
};

/// Knobs that shape diagnostic stories.
extension DiagnosticStoryKnobs on KnobsBuilder {
  /// The Severity segments; returns the chosen severity, error at start.
  skir.DiagnosticSeverity severity({String label = "Severity"}) {
    final chosen = object.segmented<String>(
      label: label,
      options: storySeverities.keys.toList(),
      initialOption: "Error",
    );
    return storySeverities[chosen]!;
  }

  /// The segments named [label] over the roles a presentation shows its
  /// diagnostics in; returns the chosen role, inspector at start.
  skir.PresentationRole role({String label = "Role"}) => object.segmented(
    label: label,
    options: const [
      skir.PresentationRole.inspector,
      skir.PresentationRole.workspace,
      skir.PresentationRole.resourceSearchResult,
    ],
    initialOption: skir.PresentationRole.inspector,
    labelBuilder: (role) => switch (role) {
      skir.PresentationRole.workspace => "Workspace",
      skir.PresentationRole.resourceSearchResult => "Search result",
      _ => "Inspector",
    },
  );
}

/// Gives [child] the diagnostic scope a renderer would, over operations
/// that never report anything, so the problems it shows come from its
/// [PortableDiagnosticSource]s.
class StoryDiagnosticScope extends HookWidget {
  const StoryDiagnosticScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    return PortableDiagnosticPreview(operations: operations, child: child);
  }
}

/// A text field of the quest named [field], framed so problems on it show
/// below it and tint it.
class StoryDiagnosedField extends StatelessWidget {
  const StoryDiagnosedField({
    required this.field,
    required this.label,
    required this.text,
    this.readOnly = false,
    super.key,
  });

  final String field;
  final String label;
  final String text;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return PortableDiagnosticFrame(
      target: storyQuestField(field),
      value: skir.DataValue.wrapStringValue(text),
      label: label,
      child: EditorTextField(
        text: text,
        readOnly: readOnly,
        semanticLabel: label,
      ),
    );
  }
}
