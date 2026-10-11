import "package:typewriter_panel/typewriter_panel.dart";

/// Displays a compact title and optional description for an editor section.
///
/// The widget owns presentation only. Callers retain responsibility for the
/// section's content, interaction, and any accessible semantics beyond this
/// text.
class Header extends StatelessWidget {
  const Header({required this.title, this.description, super.key});

  final String title;

  /// Secondary explanation displayed below [title] when present.
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (description case final value?) Text(value),
    ],
  );
}
