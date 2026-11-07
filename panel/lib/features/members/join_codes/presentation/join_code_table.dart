import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop table presentation of active invitation codes.
///
/// Rows expose pointer and keyboard operations through
/// [JoinCodeTableRowShortcuts]. This widget owns focus and selection visuals,
/// while the route owns selection and providers supply observed data. Row
/// controls submit prepared repository commands through shared local work.
class JoinCodesTable extends HookConsumerWidget {
  const JoinCodesTable({required this.selection, super.key});

  final SelectableRows<skir.JoinCode> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusedCodeId = useState<skir.RecordId?>(null);
    final codes = selection.rows.items;

    return SelectionTable<skir.JoinCode>(
      selection: selection,
      idOf: (code) => code.code,
      labels: const ["Join Code", "Type", "Expires"],
      hasScrollBody: false,
      columnWidths: const {
        0: FixedColumnWidth(48),
        1: FlexColumnWidth(2),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: FixedColumnWidth(80),
      },
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active join codes",
        description: "Generate a join code above to get started!",
      ),
      rowBuilder: (context, entry) => _buildCodeRow(
        context,
        ref,
        entry.item,
        codes,
        selection.selectedIds.value.contains(entry.id),
        focusedCodeId,
        theme,
      ),
    );
  }

  TableRow _buildCodeRow(
    BuildContext context,
    WidgetRef ref,
    skir.JoinCode code,
    List<skir.JoinCode> codes,
    bool isSelected,
    ValueNotifier<skir.RecordId?> focusedCodeId,
    ThemeData theme,
  ) {
    final fullUrl = joinCodeUrl(code.code);

    void toggleSelection() {
      if (isSelected) {
        selection.selectedIds.value = selection.selectedIds.value
            .where((selected) => selected != code.code)
            .toSet();
        return;
      }
      selection.selectedIds.value = {...selection.selectedIds.value, code.code};
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
      onSelectAll: () =>
          selection.selectedIds.value = codes.map((c) => c.code).toSet(),
      onClearSelection: () => selection.selectedIds.value = {},
      onCopy: () => _copyToClipboard(context, fullUrl),
      isSelected: isSelected,
      hasSelection: selection.selectedIds.value.isNotEmpty,
      onRevokeSelection: selection.onRemoveSelection,
      onFocusChange: updateFocus,
      child: child,
    );

    return TableRow(
      key: ValueKey(code.code),
      decoration: BoxDecoration(
        // Fill means selected; the ring layer shows focus.
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            child: withShortcuts(
              Checkbox(value: isSelected, onChanged: (_) => toggleSelection()),
            ),
          ),
        ),
        TableCell(
          child: withShortcuts(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: BlurReveal(
                      blurSigma: 3,
                      child: SelectableText(
                        fullUrl,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.space2),
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
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            child: JoinCodeTypeBadges(code: code),
          ),
        ),
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            child: CountdownBadge(
              endDate: code.expiresAt,
              onExpired: () {
                selection.selectedIds.value = selection.selectedIds.value
                    .where((selected) => selected != code.code)
                    .toSet();
              },
            ),
          ),
        ),
        TableCell(child: withShortcuts(JoinCodeRowActions(code: code))),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, "Join code copied to clipboard");
  }
}
