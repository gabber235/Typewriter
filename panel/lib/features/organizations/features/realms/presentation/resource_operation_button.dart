import "package:typewriter_panel/typewriter_panel.dart";

/// Renders an operation affordance with its authoritative disabled reason.
class ResourceOperationButton extends StatelessWidget {
  const ResourceOperationButton({
    required this.label,
    required this.description,
    this.disabledReason,
    this.onInvoke,
    super.key,
  });

  final String label;
  final String description;
  final String? disabledReason;
  final VoidCallback? onInvoke;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: disabledReason ?? description,
    child: TextButton(
      onPressed: disabledReason == null ? onInvoke : null,
      child: Text(label),
    ),
  );
}
