import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/data/default_presentation_renderer.dart";
part "renderers/data/presentation_invocation_renderer.dart";

/// Renders a binding with the type system's generated default presentation.
///
/// This is the fallback for typed fields without an explicit presentation.
/// It reports binding inspection failures through the same diagnostic surface
/// as explicit controls and delegates the resulting node back through the
/// protocol renderer, preserving normal scope routing and header behavior.
class ProtocolBoundValueEditor extends StatelessWidget {
  const ProtocolBoundValueEditor({
    required this.control,
    required this.scope,
    super.key,
  });

  final BoundControl control;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final result = scope.inspect(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    return LabeledControl(
      control: control,
      scope: scope,
      child: binding.renderDefaultPresentation(
        scope,
        nodeId: "bound.${control.binding.bindingId.value}",
      ),
    );
  }
}

/// Builds a default presentation for an inspected binding without changing
/// the binding owner or its value state.
extension InspectedBindingDefaultPresentationRendering on InspectedBinding {
  Widget renderDefaultPresentation(
    PresentationRenderScope scope, {
    required String nodeId,
    bool root = false,
    String? label,
  }) => PresentationNodeRenderer(
    node: type.generateDefaultPresentation(
      binding: reference,
      nodeId: nodeId,
      root: root,
      label: label,
      registry: scope.registry,
    ),
    scope: scope,
  );
}

/// Builds a default presentation when a concrete value is already required by
/// the caller, such as a nested collection or record renderer.
extension ResolvedBindingDefaultPresentationRendering on ResolvedBinding {
  Widget renderDefaultPresentation(
    PresentationRenderScope scope, {
    required String nodeId,
    bool root = false,
    String? label,
  }) => PresentationNodeRenderer(
    node: type.generateDefaultPresentation(
      binding: reference,
      nodeId: nodeId,
      root: root,
      label: label,
      registry: scope.registry,
    ),
    scope: scope,
  );
}

/// Adds declarative label, description, and semantic labeling to a control.
///
/// The wrapper evaluates text through the render scope and does not own the
/// control's value or interaction. Controls can omit it when an enclosing
/// header or composite surface provides the visible label.
class LabeledControl extends StatelessWidget {
  const LabeledControl({
    required this.control,
    required this.scope,
    required this.child,
    this.missing = false,
    super.key,
  });

  final BoundControl control;
  final PresentationRenderScope scope;
  final Widget child;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final inheritedDiagnostics =
        PresentationFieldDiagnostics.maybeOf(context)
            ?.exact(scope.canonical(control.binding)) ??
        const <TypeDiagnostic>[];
    final diagnostics =
        inheritedDiagnostics.isEmpty && control.label != null && missing
        ? const [
            TypeDiagnostic(
              code: TypeDiagnosticCode.missingField,
              message: "A value is required",
            ),
          ]
        : inheritedDiagnostics;

    final label = control.label == null
        ? null
        : scope.expressionText(control.label!);

    final description = control.description == null
        ? null
        : scope.expressionText(control.description!);

    final semanticLabel = resolveControlSemanticLabel(control, scope);
    final semanticChild = semanticLabel == null || semanticLabel.isEmpty
        ? child
        : MergeSemantics(
            child: Semantics(label: semanticLabel, child: child),
          );

    if ((label == null || label.isEmpty) &&
        (description == null || description.isEmpty) &&
        diagnostics.isEmpty) {
      return semanticChild;
    }

    final colors = Theme.of(context).colorScheme;
    final hasErrors = diagnostics.any(
      (diagnostic) => diagnostic.severity == TypeDiagnosticSeverity.error,
    );

    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledMessage(
          label: label,
          message: description,
          labelStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: hasErrors ? colors.error : null),
        ),
        if ((label != null && label.isNotEmpty) ||
            (description != null && description.isNotEmpty))
          const SizedBox(height: 6),

        AnimatedContainer(
          duration: 120.ms,
          decoration: hasErrors
              ? BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: context.shapes.mediumBorderRadius,
                )
              : BoxDecoration(),
          padding: hasErrors ? EdgeInsets.all(spacing.space2) : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing.space1,
            children: [
              semanticChild,
              ElasticMessageSwitcher(
                child: diagnostics.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.space2,
                        ),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            diagnostics
                                .map((diagnostic) => diagnostic.message)
                                .join("\n"),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Color.alphaBlend(
                                    colors.error.withValues(
                                      alpha: context.isDarkMode ? 0.4 : 0.9,
                                    ),
                                    Surface.colorOf(context).on(context),
                                  ),
                                ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Resolves the accessible name, preferring an explicit semantic label over
/// the visible label.
String? resolveControlSemanticLabel(
  BoundControl control,
  PresentationRenderScope scope,
) {
  final expression = control.semanticLabel ?? control.label;
  return expression == null ? null : scope.expressionText(expression);
}

/// Renders a control prefix and removes duplicate semantics when the control
/// already supplies an accessible name.
Widget? renderControlPrefix(
  BuildContext context,
  BoundControl control,
  PresentationRenderScope scope,
) {
  final prefix = control.prefix;
  if (prefix == null) return null;
  Widget child = PresentationNodeRenderer(node: prefix, scope: scope);
  if (resolveControlSemanticLabel(control, scope) case final label?
      when label.isNotEmpty) {
    child = ExcludeSemantics(child: child);
  }
  return Padding(
    padding: EdgeInsets.all(context.spacing.space2),
    child: DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: context.colors.contentSecondary),
      child: IconTheme.merge(
        data: IconThemeData(color: context.colors.contentSecondary, size: 18),
        child: child,
      ),
    ),
  );
}
