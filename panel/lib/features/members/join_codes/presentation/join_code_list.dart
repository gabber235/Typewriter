import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Mobile presentation of the active join code projection.
///
/// Selection is shared with the route so bulk actions behave identically on
/// mobile and desktop. It renders the rows [JoinCodesTab] owns. Revocation and expiry
/// visibility comes from the shared activity and local expiry projections.
class JoinCodesCardList extends HookConsumerWidget {
  const JoinCodesCardList({required this.selection, super.key});

  final SelectableRows<skir.JoinCode> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codes = selection.rows.items;

    // The empty state shows once the last leaving row is gone.
    if (selection.rows.entries.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: MaterialSymbols.link_off_rounded,
          title: "No active join codes",
          description: "Generate a join code above to get started!",
        ),
      );
    }

    final allSelected = selection.selectedIds.value.length == codes.length;
    final someSelected = selection.selectedIds.value.isNotEmpty && !allSelected;

    void handleSelectAll() {
      selection.selectedIds.value = allSelected || someSelected
          ? {}
          : codes.map((code) => code.code).toSet();
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverFloatingHeader(
          child: Container(
            color: Surface.colorOf(context),
            padding: EdgeInsets.symmetric(vertical: context.spacing.space2),
            child: Enter(
              token: MotionToken.loadIn,
              child: GestureDetector(
                onTap: handleSelectAll,
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected ? true : (someSelected ? null : false),
                      tristate: true,
                      onChanged: (_) => handleSelectAll(),
                    ),
                    Text(
                      "Select all",
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverAnimatedRows<skir.JoinCode>(
          rows: selection.rows,
          itemBuilder: (context, entry) => _child(context, entry.item, codes),
        ),
      ],
    );
  }

  Widget _child(
    BuildContext context,
    skir.JoinCode code,
    List<skir.JoinCode> codes,
  ) => Padding(
    padding: EdgeInsets.only(bottom: context.spacing.space2),
    child: JoinCodeCard(
      code: code,
      isSelected: selection.selectedIds.value.contains(code.code),
      onSelectionChanged: (selected) {
        selection.selectedIds.value = selected
            ? {...selection.selectedIds.value, code.code}
            : selection.selectedIds.value
                  .where((item) => item != code.code)
                  .toSet();
      },
      onSelectAll: () =>
          selection.selectedIds.value = codes.map((code) => code.code).toSet(),
      onClearSelection: () => selection.selectedIds.value = {},
      hasSelection: selection.selectedIds.value.isNotEmpty,
      onRevokeSelection: selection.onRemoveSelection,
    ),
  );
}
