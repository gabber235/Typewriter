import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodesCardList extends HookConsumerWidget {
  const JoinCodesCardList({
    required this.codes,
    required this.selectedCodes,
    required this.onRevokeSelection,
    super.key,
  });

  final List<OrganizationJoinCode> codes;
  final ValueNotifier<Set<skir.RecordId>> selectedCodes;
  final Future<void> Function() onRevokeSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final animated = useSliverAnimatedList(
      items: codes,
      identity: (code) => code.code,
      removedItemBuilder: (context, code, animation) =>
          _child(code, animation, deleting: true),
    );

    if (codes.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: MaterialSymbols.link_off_rounded,
          title: "No active join codes",
          description: "Generate a join code above to get started!",
        ),
      );
    }

    final allSelected = selectedCodes.value.length == codes.length;
    final someSelected = selectedCodes.value.isNotEmpty && !allSelected;

    void handleSelectAll() {
      selectedCodes.value = allSelected || someSelected
          ? {}
          : codes.map((code) => code.code).toSet();
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverFloatingHeader(
          child: Container(
            color: Surface.colorOf(context),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: StaggerEntrance(
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverAnimatedList(
          key: animated.key,
          initialItemCount: animated.items.length,
          itemBuilder: (context, index, animation) =>
              _child(animated.items[index], animation),
        ),
      ],
    );
  }

  Widget _child(
    OrganizationJoinCode code,
    Animation<double> animation, {
    bool deleting = false,
  }) => ExcludeInteraction(
    key: ValueKey(code.code),
    excluding: deleting,
    child: ElasticTransition(
      animation: animation,
      child: StaggerEntrance(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: JoinCodeCard(
            code: code,
            isSelected: selectedCodes.value.contains(code.code),
            onSelectionChanged: (selected) {
              selectedCodes.value = selected
                  ? {...selectedCodes.value, code.code}
                  : selectedCodes.value
                        .where((item) => item != code.code)
                        .toSet();
            },
            onSelectAll: () =>
                selectedCodes.value = codes.map((code) => code.code).toSet(),
            onClearSelection: () => selectedCodes.value = {},
            hasSelection: selectedCodes.value.isNotEmpty,
            onRevokeSelection: onRevokeSelection,
          ),
        ),
      ),
    ),
  );
}
