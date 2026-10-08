import "package:typewriter_panel/typewriter_panel.dart";

/// Displays the compact heading used within a [Section] or grouped panel.
class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, super.key}) : super();

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 14),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
