import "package:typewriter_panel/typewriter_panel.dart";

/// Requires an explicit replacement before differing structures are edited.
final class MixedCollectionControl extends StatelessWidget {
  const MixedCollectionControl({required this.onReplace, super.key});

  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text("Different collections"),
      const MixedValueMessage(),
      SizedBox(height: context.spacing.space2),
      OutlinedButton(onPressed: onReplace, child: const Text("Replace all")),
    ],
  );
}
