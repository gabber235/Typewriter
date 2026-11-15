import "package:typewriter_panel/typewriter_panel.dart";

/// One choice of a [CheckOptionSet]: its key, its label and whether it can
/// be changed here.
@immutable
final class CheckChoice<K> {
  const CheckChoice({
    required this.key,
    required this.label,
    this.enabled = true,
  });

  final K key;
  final String label;
  final bool enabled;
}

/// A set of known choices over the sets several items hold, one
/// [CheckOption] per choice: checked when every item holds it, striped with
/// "1 of 2" when some do.
///
/// A press on a choice only some items hold gives it to all of them, the
/// next takes it from all, and the one after gives each item back what it
/// held before. A choice all or none hold switches between the two. Every
/// press hands [onChanged] the next set of every item, in the order of
/// [held], so the owner writes all of them at once or none.
class CheckOptionSet<K> extends HookWidget {
  const CheckOptionSet({
    required this.choices,
    required this.held,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final List<CheckChoice<K>> choices;

  /// The choices each item holds now.
  final List<Set<K>> held;
  final ValueChanged<List<Set<K>>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Which items held a choice before the press that gave it to all, and
    // the sets that press left, so a change from anywhere else forgets it.
    final before = useRef(<K, (List<bool>, List<Set<K>>)>{});

    void press(K key) {
      final holding = [for (final set in held) set.contains(key)];
      final all = holding.every((holds) => holds);
      final remembered = switch (before.value.remove(key)) {
        (final places, final left) when _sameSets(left, held) => places,
        _ => null,
      };
      final next = remembered != null && !all
          ? remembered
          : [for (final _ in holding) !all];
      final written = [
        for (final (index, set) in held.indexed)
          {...set.where((held) => held != key), if (next[index]) key},
      ];
      final places = remembered ?? (all ? null : holding);
      if (places != null &&
          next != remembered &&
          places.any((holds) => holds)) {
        before.value[key] = (places, written);
      }
      onChanged(written);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in choices)
          () {
            final count = held.where((set) => set.contains(choice.key)).length;
            return CheckOption(
              key: ValueKey(choice.key),
              label: choice.label,
              value: count == held.length
                  ? true
                  : count == 0
                  ? false
                  : null,
              detail: "$count of ${held.length}",
              onPressed: enabled && choice.enabled
                  ? () => press(choice.key)
                  : null,
            );
          }(),
      ],
    );
  }

  static bool _sameSets<K>(List<Set<K>> a, List<Set<K>> b) =>
      a.length == b.length &&
      a.indexed.every((entry) => setEquals(entry.$2, b[entry.$1]));
}
