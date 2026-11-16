import "package:typewriter_panel/typewriter_panel.dart";

/// Presents the full screen empty state for a missing collection or resource.
///
/// The optional action is rendered only when [buttonText] is supplied, and
/// [child] adds guidance below the [title], such as what a search accepts.
/// This widget does not infer why the collection is empty or own the action's
/// state; callers provide the message and recovery operation.
class EmptyScreen extends HookConsumerWidget {
  const EmptyScreen({
    this.title,
    this.child,
    this.small = false,
    this.buttonText,
    this.onPressed,
    super.key,
  }) : super();

  final bool small;
  final String? title;
  final Widget? child;
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
        if (title case final title?)
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontSize: small ? 20 : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (child case final child?)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child,
          ),
        SizedBox(height: small ? 12 : 24),
        if (buttonText != null)
          Button(
            face: ButtonFace.filled,
            icon: const Icones(Fa6Solid.plus),
            label: buttonText ?? "",
            onPressed: onPressed,
          ),
        if (!small) const Spacer(),
      ],
    );
  }
}
