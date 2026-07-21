import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_badges.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_row_actions.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_table_row_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_url.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodesTable extends HookConsumerWidget {
  const JoinCodesTable({
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
    final focusedCodeId = useState<skir.RecordId?>(null);
    final animated = useAnimatedTable(
      items: codes,
      identity: (code) => code.code,
      removedItemBuilder: (context, code, animation) => _buildCodeRow(
        context,
        ref,
        code,
        selectedCodes.value.contains(code.code),
        focusedCodeId,
        theme,
      ),
    );

    final allSelected =
        codes.isNotEmpty && selectedCodes.value.length == codes.length;
    final someSelected =
        selectedCodes.value.isNotEmpty &&
        selectedCodes.value.length < codes.length;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: AnimatedTable(
        key: animated.key,
        initialItemCount: animated.items.length,
        columnWidths: const {
          0: FixedColumnWidth(48),
          1: FlexColumnWidth(2),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
          4: FixedColumnWidth(80),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        headerRows: [
          TableRow(
            decoration: BoxDecoration(color: Surface.colorOf(context)),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: StaggerEntrance(
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
                          selectedCodes.value = codes
                              .map((code) => code.code)
                              .toSet();
                        }
                      },
                    ),
                  ),
                ),
              ),
              _headerCell(theme, "Join Code"),
              _headerCell(theme, "Type"),
              _headerCell(theme, "Expires"),
              const TableCell(child: SizedBox.shrink()),
            ],
          ),
        ],
        emptyBuilder: (context) => const EmptyState(
          icon: MaterialSymbols.link_off_rounded,
          title: "No active join codes",
          description: "Generate a join code above to get started!",
        ),
        transitionBuilder: (context, animation, child) =>
            ElasticTransition(animation: animation, child: child),
        tableBuilder: (context, table) => Surface(
          color: Surface.colorOf(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: table,
          ),
        ),
        rowBuilder: (context, index, animation) {
          final code = animated.items[index];
          return _buildCodeRow(
            context,
            ref,
            code,
            selectedCodes.value.contains(code.code),
            focusedCodeId,
            theme,
          );
        },
      ),
    );
  }

  TableCell _headerCell(ThemeData theme, String label) {
    return TableCell(
      child: StaggerEntrance(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildCodeRow(
    BuildContext context,
    WidgetRef ref,
    OrganizationJoinCode code,
    bool isSelected,
    ValueNotifier<skir.RecordId?> focusedCodeId,
    ThemeData theme,
  ) {
    final isFocused = focusedCodeId.value == code.code;
    final fullUrl = joinCodeUrl(code.code);

    void toggleSelection() {
      if (isSelected) {
        selectedCodes.value = selectedCodes.value
            .where((selected) => selected != code.code)
            .toSet();
        return;
      }
      selectedCodes.value = {...selectedCodes.value, code.code};
    }

    void updateFocus(bool focused) {
      if (focused) {
        focusedCodeId.value = code.code;
      } else if (focusedCodeId.value == code.code) {
        focusedCodeId.value = null;
      }
    }

    Widget withShortcuts(Widget child) => JoinCodeTableRowShortcuts(
      code: code,
      onToggleSelection: toggleSelection,
      onSelectAll: () => selectedCodes.value = codes.map((c) => c.code).toSet(),
      onClearSelection: () => selectedCodes.value = {},
      onCopy: () => _copyToClipboard(context, fullUrl),
      isSelected: isSelected,
      hasSelection: selectedCodes.value.isNotEmpty,
      onRevokeSelection: onRevokeSelection,
      onFocusChange: updateFocus,
      child: child,
    );

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
          child: StaggerEntrance(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: withShortcuts(
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => toggleSelection(),
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: StaggerEntrance(
            child: withShortcuts(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
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
          ),
        ),
        TableCell(
          child: StaggerEntrance(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: JoinCodeTypeBadges(code: code),
            ),
          ),
        ),
        TableCell(
          child: StaggerEntrance(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: CountdownBadge(
                endDate: code.expiresAt,
                onExpired: () {
                  selectedCodes.value = selectedCodes.value
                      .where((selected) => selected != code.code)
                      .toSet();
                  ref
                      .read(organizationJoinCodesProvider.notifier)
                      .cleanupExpiredCodes();
                },
              ),
            ),
          ),
        ),
        TableCell(
          child: StaggerEntrance(
            child: withShortcuts(JoinCodeRowActions(code: code)),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, "Join code copied to clipboard");
  }
}
