part of "../../content_renderer.dart";

extension BadgeElementRendering on BadgeElement {
  Widget render(BuildContext context, PresentationRenderScope scope) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(scope.expressionText(label)),
    avatar: Icon(Icons.circle, size: 10, color: tone._badgeTone(context)),
  );
}

extension on String {
  Color _badgeTone(BuildContext context) => switch (this) {
    "danger" => Theme.of(context).colorScheme.error,
    "success" => context.colors.success,
    "warning" => context.colors.warning,
    _ => Theme.of(context).colorScheme.primary,
  };
}
