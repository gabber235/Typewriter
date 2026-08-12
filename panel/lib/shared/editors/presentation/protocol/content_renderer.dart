import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension ContentElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    return switch (element) {
      TextElement(:final value) => Text(scope.expressionText(value)),
      RichTextElement(:final value) => SelectableText(
        scope.expressionText(value),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      MarkdownElement(:final value) => SelectableText(
        scope.expressionText(value),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      IconElement() => element._renderIcon(context, scope),
      ImageElement() => element._renderImage(context, scope),
      BadgeElement() => Chip(
        visualDensity: VisualDensity.compact,
        label: Text(scope.expressionText(element.label)),
        avatar: Icon(
          Icons.circle,
          size: 10,
          color: element.tone._tone(context),
        ),
      ),
      ProgressElement() => element._renderProgress(context, scope),
      _ => const SizedBox.shrink(),
    };
  }
}

extension on IconElement {
  Widget _renderIcon(BuildContext context, PresentationRenderScope scope) {
    final result = scope.evaluate(name);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final icon = result.valueOrNull?.iconValueOrNull;
    if (icon == null) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Icon content must evaluate to the nominal Icon type",
        ),
      ]);
    }
    final label = semanticLabel == null
        ? null
        : scope.expressionText(semanticLabel!);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: Icones.value(icon)),
    );
  }
}

extension on ImageElement {
  Widget _renderImage(BuildContext context, PresentationRenderScope scope) {
    final source = scope.expressionText(this.source);
    final uri = Uri.tryParse(source);
    if (uri == null || uri.scheme != "https") {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Image source must use HTTPS",
        ),
      ]);
    }
    final label = semanticLabel == null
        ? null
        : scope.expressionText(semanticLabel!);
    return Image.network(
      source,
      semanticLabel: label,
      errorBuilder: (context, error, stackTrace) =>
          presentationDiagnostic(context, [
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "Image could not be loaded",
            ),
          ]),
    );
  }
}

extension on ProgressElement {
  Widget _renderProgress(BuildContext context, PresentationRenderScope scope) {
    final value = scope.evaluate(this.value).valueOrNull._number;
    final maximum = scope.evaluate(this.maximum).valueOrNull._number;
    if (value == null || maximum == null || maximum <= 0) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message:
              "Progress values must be numeric and maximum must be positive",
        ),
      ]);
    }
    final label = this.label == null ? null : scope.expressionText(this.label!);
    return Semantics(
      label: label,
      value: "$value of $maximum",
      child: LinearProgressIndicator(value: (value / maximum).clamp(0, 1)),
    );
  }
}

extension on DataValue? {
  double? get _number => switch (this) {
    IntegerValue(:final value) => value.toDouble(),
    FloatValue(:final value) => value,
    DecimalValue(:final value) => double.tryParse(value),
    _ => null,
  };
}

extension on String {
  Color _tone(BuildContext context) => switch (this) {
    "danger" => Theme.of(context).colorScheme.error,
    "success" => context.colors.success,
    "warning" => context.colors.warning,
    _ => Theme.of(context).colorScheme.primary,
  };
}
