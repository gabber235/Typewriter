import "package:typewriter_panel/typewriter_panel.dart";

/// Presents the full screen empty state for a missing collection or resource.
///
/// The optional action is rendered only when [buttonText] is supplied. This
/// widget does not infer why the collection is empty or own the action's state;
/// callers provide the message and recovery operation.
class EmptyScreen extends HookConsumerWidget {
  const EmptyScreen({
    required this.title,
    this.small = false,
    this.buttonText,
    this.onPressed,
    super.key,
  }) : super();

  final bool small;
  final String title;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (!small) const Spacer(),
        Expanded(
          flex: 2,
          child: const RiveAsset(
            asset: "assets/cute_robot.riv",
            stateMachineName: "Motion",
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium!
              .copyWith(fontSize: small ? 20 : 25, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: small ? 12 : 24),
        if (buttonText != null)
          FilledButton.icon(
            label: Text(buttonText ?? ""),
            onPressed: onPressed,
            icon: const Icones(Fa6Solid.plus),
          ),
        if (!small) const Spacer(),
      ],
    );
  }
}
