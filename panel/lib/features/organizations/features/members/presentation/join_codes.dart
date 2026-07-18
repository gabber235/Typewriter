part of "route.dart";

class _JoinCodesTab extends HookConsumerWidget {
  const _JoinCodesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codesAsync = ref.watch(organizationJoinCodesProvider);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedCodes = useState<Set<skir.RecordId>>({});
    final joinCodeOptions = useState(const JoinCodeOptions());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SecretField(
                  title: "Invite Link",
                  description:
                      "Generate a unique link to invite new members to your organization.",
                  prefix: "https://panel.typewritermc.com/join/",
                  onGenerate: () => ref
                      .read(organizationProvider.notifier)
                      .generateJoinCode(options: joinCodeOptions.value),
                  generateButtonText: "Generate Link",
                  regenerateButtonText: "New Link",
                  copyButtonText: "Copy Link",
                ),
                const SizedBox(height: 8),
                rolesAsync.when(
                  data: (roles) => _JoinCodeSettings(
                    initialOptions: joinCodeOptions.value,
                    availableRoles: roles,
                    onOptionsChanged: (options) =>
                        joinCodeOptions.value = options,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Text("Active Links", style: theme.textTheme.titleMedium),
              if (selectedCodes.value.isNotEmpty)
                _BulkJoinCodeActions(
                  selectedCount: selectedCodes.value.length,
                  selectedCodes: selectedCodes.value,
                  onClearSelection: () => selectedCodes.value = {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        codesAsync(
          name: "Join Codes",
          builder: (codes) => context.isDesktop
              ? _JoinCodesTable(codes: codes, selectedCodes: selectedCodes)
              : _JoinCodesCardList(codes: codes, selectedCodes: selectedCodes),
          loading: (name) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LoadingIndicator(message: "Loading $name..."),
            ),
          ),
          error: (title, message) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ErrorScreen.small(title: title, message: message),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BulkJoinCodeActions extends HookConsumerWidget {
  const _BulkJoinCodeActions({
    required this.selectedCount,
    required this.selectedCodes,
    required this.onClearSelection,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedCodes;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _SelectedChip(
          selectedCount: selectedCount,
          onClearSelection: onClearSelection,
        ),
        LoadingButton.outlinedIcon(
          onPressed: () => _confirmBulkRevoke(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          icon: const Icon(Icons.link_off, size: 18),
          label: const Text("Revoke All"),
        ),
      ],
    );
  }

  Future<void> _confirmBulkRevoke(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke $selectedCount link(s)?",
      content:
          "Are you sure you want to revoke these invite links? They will no longer work.",
      confirmText: "Revoke All",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        for (final code in selectedCodes) {
          await ref
              .read(organizationJoinCodesProvider.notifier)
              .revokeCode(code);
        }
        onClearSelection();
      },
    );
  }
}

class _JoinCodesTable extends HookConsumerWidget {
  const _JoinCodesTable({required this.codes, required this.selectedCodes});

  final List<OrganizationJoinCode> codes;
  final ValueNotifier<Set<skir.RecordId>> selectedCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusedRowIndex = useState(-1);

    if (codes.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active invite links",
        description: "Generate an invite link above to get started!",
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
                    "Invite Link",
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
    final fullUrl = "https://panel.typewritermc.com/join/${code.code}";

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
                  tooltip: "Copy link",
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: _JoinCodeTypeBadges(code: code),
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
        TableCell(child: _JoinCodeRowActions(code: code)),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Link copied to clipboard"),
        duration: 2.seconds,
      ),
    );
  }
}

/// Displays badges for join code type (single-use and/or auto-accept).
class _JoinCodeTypeBadges extends StatelessWidget {
  const _JoinCodeTypeBadges({required this.code});

  final OrganizationJoinCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      spacing: 6,
      children: [
        if (code.singleUse)
          _TypeBadge(
            icon: Icons.looks_one_rounded,
            label: "Single-use",
            color: theme.colorScheme.tertiary,
            backgroundColor: theme.colorScheme.tertiaryContainer,
          )
        else
          _TypeBadge(
            icon: Icons.all_inclusive_rounded,
            label: "Multi-use",
            color: theme.colorScheme.onSurfaceVariant,
            backgroundColor: Surface.colorOf(context),
          ),
        if (code.autoAccept.roleIds.isNotEmpty)
          _TypeBadge(
            icon: Icons.flash_on_rounded,
            label: "Auto-accept",
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinCodeRowActions extends HookConsumerWidget {
  const _JoinCodeRowActions({required this.code});

  final OrganizationJoinCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRevoking = useState(false);

    if (isRevoking.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
        onPressed: () => _confirmRevokeCode(context, ref, isRevoking),
        tooltip: "Revoke link",
      ),
    );
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this invite link?",
      content:
          "Are you sure you want to revoke this link? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}

class _JoinCodesCardList extends HookConsumerWidget {
  const _JoinCodesCardList({required this.codes, required this.selectedCodes});

  final List<OrganizationJoinCode> codes;
  final ValueNotifier<Set<skir.RecordId>> selectedCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (codes.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active invite links",
        description: "Generate an invite link above to get started!",
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
          return _JoinCodeCard(
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

class _JoinCodeCard extends HookConsumerWidget {
  const _JoinCodeCard({
    required this.code,
    required this.index,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final OrganizationJoinCode code;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = useState(false);
    final isRevoking = useState(false);
    final fullUrl = "https://panel.typewritermc.com/join/${code.code}";

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      child: isRevoking.value
          ? const SizedBox.shrink()
          : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          )
                        : Surface.colorOf(context),
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => isExpanded.value = !isExpanded.value,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => onSelectionChanged(!isSelected),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green
                                          : theme.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check : Icons.link,
                                      color: isSelected
                                          ? Colors.white
                                          : theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BlurReveal(
                                        blurSigma: 3,
                                        child: Text(
                                          fullUrl,
                                          style: TextStyle(
                                            fontFamily: "monospace",
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          CountdownBadge(
                                            endDate: code.expiresAt,
                                            onExpired: () => ref.invalidate(
                                              organizationJoinCodesProvider,
                                            ),
                                          ),
                                          _JoinCodeTypeBadges(code: code),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded.value
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: isExpanded.value
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      height: 1,
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _copyToClipboard(
                                                context,
                                                fullUrl,
                                              ),
                                              icon: const Icon(
                                                Icons.copy,
                                                size: 18,
                                              ),
                                              label: const Text("Copy Link"),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _confirmRevokeCode(
                                                    context,
                                                    ref,
                                                    isRevoking,
                                                  ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.error,
                                                side: BorderSide(
                                                  color: theme.colorScheme.error
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.link_off,
                                                size: 18,
                                              ),
                                              label: const Text("Revoke"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 200.ms)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 300.ms,
                  delay: (50 * index).ms,
                ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Link copied to clipboard"),
        duration: 2.seconds,
      ),
    );
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this invite link?",
      content:
          "Are you sure you want to revoke this link? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        onSelectionChanged(false);
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}

/// Expandable settings panel for join code generation.
/// This widget is designed to be used alongside SecretField without
/// the SecretField knowing about join code specifics.
class _JoinCodeSettings extends HookConsumerWidget {
  const _JoinCodeSettings({
    required this.onOptionsChanged,
    required this.availableRoles,
    this.initialOptions = const JoinCodeOptions(),
  });

  final ValueChanged<JoinCodeOptions> onOptionsChanged;
  final JoinCodeOptions initialOptions;
  final List<OrganizationRole> availableRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = useState(false);
    final options = useState(initialOptions);

    void updateOptions(JoinCodeOptions newOptions) {
      options.value = newOptions;
      onOptionsChanged(newOptions);
    }

    void updateDuration(Duration duration) {
      updateOptions(
        options.value.copyWith(
          expiration: JoinCodeExpiration.duration(duration),
        ),
      );
    }

    final isCustomized = _hasNonDefaultOptions(options.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => isExpanded.value = !isExpanded.value,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded.value ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  "Advanced options",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Customized",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                    .animate(target: isCustomized ? 1.0 : 0.0)
                    .scaleXY(
                      begin: 0.7,
                      end: 1.0,
                      duration: isCustomized ? 750.ms : 400.ms,
                      curve: isCustomized
                          ? ElasticOutCurve(0.4)
                          : Curves.fastOutSlowIn,
                    )
                    .fade(begin: 0.0, end: 1.0, duration: 400.ms),
              ],
            ),
          ),
        ),

        AnimatedSize(
          duration: 200.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: isExpanded.value
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Surface.colorOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingRow(
                        title: "Single-use",
                        description: "Code becomes invalid after first use",
                        trailing: Switch(
                          value: options.value.singleUse,
                          onChanged: (value) => updateOptions(
                            options.value.copyWith(singleUse: value),
                          ),
                        ),
                      ),
                      const Divider(height: 24),

                      _SettingRow(
                        title: "Expires after",
                        description: "How long the invite link stays active",
                        trailing: Switch(
                          value: !_isNeverExpires(options.value.expiration),
                          onChanged: (enabled) {
                            if (enabled) {
                              updateDuration(7.days);
                            } else {
                              updateOptions(
                                options.value.copyWith(
                                  expiration: const JoinCodeExpiration.never(),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      if (!_isNeverExpires(options.value.expiration)) ...[
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        _DurationInput(
                          duration:
                              (options.value.expiration
                                      as JoinCodeExpirationDuration)
                                  .duration,
                          onDurationChanged: updateDuration,
                        ),
                      ],
                      const Divider(height: 24),

                      _SettingRow(
                        title: "Auto-accept",
                        description:
                            "Automatically accept users without approval",
                        trailing: Switch(
                          value: options.value.autoAcceptRoleIds.isNotEmpty,
                          onChanged: (enabled) {
                            if (enabled) {
                              // Default to default roles
                              final defaultRoleIds = availableRoles
                                  .where((r) => r.defaultRole)
                                  .map((r) => r.roleId)
                                  .toList();

                              assert(
                                defaultRoleIds.isNotEmpty,
                                "Database should have never allowed to not have any default roles",
                              );

                              updateOptions(
                                options.value.copyWith(
                                  autoAcceptRoleIds: defaultRoleIds,
                                ),
                              );
                            } else {
                              updateOptions(
                                options.value.copyWith(autoAcceptRoleIds: []),
                              );
                            }
                          },
                        ),
                      ),

                      if (options.value.autoAcceptRoleIds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Roles to assign:",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RoleMultiselectChips(
                          availableRoles: availableRoles,
                          selectedRoles: availableRoles
                              .where(
                                (role) => options.value.autoAcceptRoleIds
                                    .contains(role.roleId),
                              )
                              .toList(),
                          onRolesChanged: (newRoles) {
                            updateOptions(
                              options.value.copyWith(
                                autoAcceptRoleIds: newRoles
                                    .map((role) => role.roleId)
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  bool _hasNonDefaultOptions(JoinCodeOptions options) {
    return !options.singleUse ||
        !_isDuration(options.expiration, 7.days) ||
        options.autoAcceptRoleIds.isNotEmpty;
  }

  bool _isNeverExpires(JoinCodeExpiration expiration) {
    return expiration is JoinCodeExpirationNever;
  }

  bool _isDuration(JoinCodeExpiration expiration, Duration target) {
    if (expiration is! JoinCodeExpirationDuration) return false;
    return expiration.duration == target;
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.description,
    required this.trailing,
  });

  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Surface.colorOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DurationInput extends HookWidget {
  const _DurationInput({
    required this.duration,
    required this.onDurationChanged,
  });

  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;

  static const _presetDurations = [
    Duration(hours: 1),
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
  ];

  Widget _presets() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final duration in _presetDurations)
          _PresetChip(
            label: prettify(duration),
            isSelected: duration == this.duration,
            onTap: () => onDurationChanged(duration),
          ),
      ],
    );
  }

  String prettify(Duration duration) {
    return prettyDuration(
      duration,
      abbreviated: true,
      delimiter: " ",
      spacer: "",
      tersity: DurationTersity.hour,
      upperTersity: DurationTersity.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inlinePresets = context.responsive(mobile: false, tablet: true);

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!inlinePresets) _presets(),
        ValidatedTextField<Duration>(
          value: duration,
          name: "Expiration period",
          icon: Bi.stopwatch_fill,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[\dwdhminsu ]")),
          ],
          decoration: InputDecoration(
            suffix: inlinePresets ? _presets() : null,
          ),
          surroundingActions: [
            for (final (index, duration) in _presetDurations.indexed)
              ActionShortcut(
                id: "preset-duration-$index",
                label: "Preset ${prettify(duration)}",
                description: "Set experation to ${prettify(duration)}",
                activators: [
                  SingleActivator(
                    LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index),
                  ),
                  SingleActivator(
                    LogicalKeyboardKey(
                      LogicalKeyboardKey.numpad1.keyId + index,
                    ),
                  ),
                ],
                onInvoke: (_) => onDurationChanged(duration),
                priority: 10,
              ),
          ],
          deserialize: prettify,
          serialize: (value) => parseDuration(value, separator: " "),
          formatted: (value) {
            final formatted = prettyDuration(
              value,
              abbreviated: false,
              tersity: DurationTersity.millisecond,
              upperTersity: DurationTersity.day,
            );
            return "Valid Duration: $formatted";
          },
          validator: (value) {
            if (value.isNegative) {
              return "Duration must be positive";
            }
            if (value.inMinutes < 60) {
              return "Duration must be at least 1 hour";
            }
            return null;
          },
          onChanged: onDurationChanged,
        ),
      ],
    );
  }
}
