part of "../../composite_input_renderer.dart";

final class _MapEntryTracker {
  var _nextIdentity = 0;

  List<_MapEntrySlot> initialize(List<DataMapEntry> entries) => [
    for (final entry in entries) _newSlot(entry),
  ];

  List<_MapEntrySlot> reconcile(
    List<_MapEntrySlot> previous,
    List<DataMapEntry> current,
  ) {
    final result = List<_MapEntrySlot?>.filled(current.length, null);
    final available = List<bool>.filled(previous.length, true);

    for (var currentIndex = 0; currentIndex < current.length; currentIndex++) {
      final oldIndex = _matchingKeyIndex(
        previous,
        available,
        current[currentIndex].key,
      );
      if (oldIndex == null) continue;
      available[oldIndex] = false;
      result[currentIndex] = previous[oldIndex].withEntry(
        current[currentIndex],
      );
    }

    for (var currentIndex = 0; currentIndex < current.length; currentIndex++) {
      if (result[currentIndex] != null) continue;
      if (currentIndex < previous.length && available[currentIndex]) {
        available[currentIndex] = false;
        result[currentIndex] = previous[currentIndex].withEntry(
          current[currentIndex],
        );
        continue;
      }
      result[currentIndex] = _newSlot(current[currentIndex]);
    }

    return result.cast<_MapEntrySlot>();
  }

  int? _matchingKeyIndex(
    List<_MapEntrySlot> slots,
    List<bool> available,
    DataValue key,
  ) {
    for (var index = 0; index < slots.length; index++) {
      if (available[index] && slots[index].entry.key == key) return index;
    }
    return null;
  }

  _MapEntrySlot _newSlot(DataMapEntry entry) =>
      _MapEntrySlot(entry: entry, identity: _MapEntryIdentity(_nextIdentity++));
}

final class _MapEntrySlot {
  const _MapEntrySlot({required this.entry, required this.identity});

  final DataMapEntry entry;
  final _MapEntryIdentity identity;

  _MapEntrySlot withEntry(DataMapEntry entry) =>
      _MapEntrySlot(entry: entry, identity: identity);
}

final class _MapEntryIdentity {
  const _MapEntryIdentity(this.id);

  final int id;
}

class _MapEntryField extends StatelessWidget {
  const _MapEntryField({
    required this.child,
    this.label,
    this.emphasized = false,
  });

  final String? label;
  final Widget child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = emphasized
        ? colors.primaryContainer.withValues(alpha: 0.45)
        : colors.surfaceContainer;
    final border = emphasized
        ? colors.primary.withValues(alpha: 0.24)
        : colors.outlineVariant;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: context.shapes.smallBorderRadius,
        ),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: context.spacing.space1,
            children: [
              if (label case final label?)
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: emphasized
                        ? colors.primary
                        : context.colors.contentSecondary,
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
