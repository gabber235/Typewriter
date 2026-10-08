import "package:typewriter_panel/typewriter_panel.dart";

/// Displays an identifier that users may need to copy or compare while
/// inspecting an object.
///
/// The value is selectable so inspection and diagnostic surfaces do not force
/// users to transcribe it manually. This widget does not format or shorten the
/// supplied identifier.
class Identifier extends StatelessWidget {
  const Identifier({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      id,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.colors.contentSecondary),
    );
  }
}
