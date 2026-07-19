import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_card.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/empty_state.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";

class JoinCodesCardList extends HookConsumerWidget {
  const JoinCodesCardList({
    required this.codes,
    required this.selectedCodes,
    super.key,
  });

  final List<OrganizationJoinCode> codes;
  final ValueNotifier<Set<skir.RecordId>> selectedCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (codes.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active join codes",
        description: "Generate a join code above to get started!",
      );
    }

    final allSelected =
        codes.isNotEmpty && selectedCodes.value.length == codes.length;
    final someSelected =
        selectedCodes.value.isNotEmpty &&
        selectedCodes.value.length < codes.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selectedCodes.value = {};
      } else {
        selectedCodes.value = codes.map((c) => c.code).toSet();
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: handleSelectAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Surface.colorOf(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected ? true : (someSelected ? null : false),
                  tristate: true,
                  onChanged: (_) => handleSelectAll(),
                ),
                Text(
                  "Select all",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        ...codes.asMap().entries.map((entry) {
          final index = entry.key;
          final code = entry.value;
          return JoinCodeCard(
            key: ValueKey(code.code),
            code: code,
            index: index,
            isSelected: selectedCodes.value.contains(code.code),
            onSelectionChanged: (selected) {
              if (selected) {
                selectedCodes.value = {...selectedCodes.value, code.code};
              } else {
                selectedCodes.value = selectedCodes.value
                    .where((c) => c != code.code)
                    .toSet();
              }
            },
          );
        }),
      ],
    );
  }
}
