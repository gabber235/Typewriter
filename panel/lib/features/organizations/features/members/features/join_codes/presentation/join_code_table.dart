import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_badges.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_row_actions.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_url.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/blur_reveal.dart";
import "package:typewriter_panel/shared/ui/components/countdown_badge.dart";
import "package:typewriter_panel/shared/ui/components/empty_state.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";

class JoinCodesTable extends HookConsumerWidget {
  const JoinCodesTable({
    required this.codes,
    required this.selectedCodes,
    super.key,
  });

  final List<OrganizationJoinCode> codes;
  final ValueNotifier<Set<skir.RecordId>> selectedCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusedRowIndex = useState(-1);

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

    return Container(
      decoration: BoxDecoration(
        color: Surface.colorOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(48),
          1: FlexColumnWidth(2),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
          4: FixedColumnWidth(80),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: Surface.colorOf(context)),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (value) {
                      if (allSelected || someSelected) {
                        selectedCodes.value = {};
                      } else {
                        selectedCodes.value = codes.map((c) => c.code).toSet();
                      }
                    },
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Join Code",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Type",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Expires",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const TableCell(child: SizedBox.shrink()),
            ],
          ),
          for (final (index, code) in codes.indexed)
            _buildCodeRow(
              context,
              ref,
              code,
              index,
              selectedCodes.value.contains(code.code),
              focusedRowIndex,
              theme,
            ),
        ],
      ),
    );
  }

  TableRow _buildCodeRow(
    BuildContext context,
    WidgetRef ref,
    OrganizationJoinCode code,
    int index,
    bool isSelected,
    ValueNotifier<int> focusedRowIndex,
    ThemeData theme,
  ) {
    final isFocused = focusedRowIndex.value == index;
    final fullUrl = joinCodeUrl(code.code);

    return TableRow(
      key: ValueKey(code.code),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: isFocused ? 0.24 : 0.12,
              )
            : isFocused
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                if (isSelected) {
                  selectedCodes.value = selectedCodes.value
                      .where((c) => c != code.code)
                      .toSet();
                } else {
                  selectedCodes.value = {...selectedCodes.value, code.code};
                }
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: BlurReveal(
                    blurSigma: 3,
                    child: SelectableText(
                      fullUrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyToClipboard(context, fullUrl),
                  tooltip: "Copy Join Code",
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: JoinCodeTypeBadges(code: code),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: CountdownBadge(
              endDate: code.expiresAt,
              onExpired: () => ref.invalidate(organizationJoinCodesProvider),
            ),
          ),
        ),
        TableCell(child: JoinCodeRowActions(code: code)),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Join code copied to clipboard"),
        duration: 2.seconds,
      ),
    );
  }
}

/// Displays badges for join code type (single-use and/or auto-accept).
