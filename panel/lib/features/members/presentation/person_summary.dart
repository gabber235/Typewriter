import "package:typewriter_panel/typewriter_panel.dart";

/// A person's name over their email, as member and join request cards show
/// them beside the avatar. Either line is left out when unknown.
class PersonSummary extends StatelessWidget {
  const PersonSummary({required this.name, required this.email, super.key});

  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyMedium!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        if (name case final name?)
          Text(
            name,
            style: text.copyWith(fontVariations: [.weight(600)], fontSize: 15),
          ),
        if (email case final email?)
          Text(
            email,
            style: text.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
