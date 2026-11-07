import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates join code generation, live projection display, selection, and
/// bulk revocation for the route. It keeps transient UI intent locally while
/// [OrganizationJoinCodes] remains the owner of server backed code state.
/// Bulk revocation submits captured visible ids sequentially and stops at the
/// first failed or uncertain reply. Local work owns each submission separately.
class JoinCodesTab extends HookConsumerWidget {
  const JoinCodesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codesAsync = ref.watch(visibleOrganizationJoinCodesProvider);
    // One rows handle per tab, above the data builder: the table, the card
    // list and the bulk bar's revokeSelection share it.
    final rows = useAnimatedRows(
      items: codesAsync.value ?? const <skir.JoinCode>[],
      identity: (code) => code.code,
      ready: codesAsync.hasValue,
    );
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedCodes = useState<Set<skir.RecordId>>({});
    final joinCodeOptions = useState(const JoinCodeOptions());
    final liveCodes = useRef<List<skir.JoinCode>>([]);

    final isRevokingSelection = useRef(false);

    // The card reveals the code it generated until the code leaves the
    // authoritative list, by revocation or by its single use; a new key then
    // resets the card so it never offers a code that no longer works.
    final generatedCode = useRef<String?>(null);
    final generatedCodeCard = useState(0);
    ref.listen(organizationJoinCodesProvider, (previous, next) {
      bool lists(AsyncValue<List<skir.JoinCode>>? codes) =>
          codes?.value?.any((code) => code.code.id == generatedCode.value) ??
          false;
      if (generatedCode.value == null || !lists(previous) || lists(next)) {
        return;
      }
      generatedCode.value = null;
      generatedCodeCard.value++;
    });

    useEffect(() {
      final codeIds = liveCodes.value.map((code) => code.code).toSet();
      final validSelection = selectedCodes.value.intersection(codeIds);
      if (validSelection.length == selectedCodes.value.length) return null;

      selectedCodes.value = selectedCodes.value.intersection(codeIds);
      return null;
    }, [liveCodes.value, selectedCodes.value]);

    Future<void> revokeSelection() async {
      if (isRevokingSelection.value) return;
      final codeIds = liveCodes.value.map((code) => code.code).toSet();
      final codesToRevoke = selectedCodes.value.intersection(codeIds);
      if (codesToRevoke.isEmpty) {
        selectedCodes.value = {};
        return;
      }

      isRevokingSelection.value = true;
      try {
        await showConfirmationDialogue(
          context: context,
          title: "Revoke ${codesToRevoke.length} join code(s)?",
          content: "Are you sure you want to revoke these join codes? They will no longer work.",
          confirmText: "Revoke All",
          confirmIcon: Fa6Solid.link_slash,
          onConfirm: () async {
            for (final code in codesToRevoke) {
              // The row stays struck through until the revoke event takes it
              // out with listOut.
              await rows.sending(
                [code],
                () => ref.executeMembership(
                  ref.membershipCommands.revoke(code),
                  (response) => response.requireAccepted(),
                ),
              );
            }
            selectedCodes.value = {};
          },
        );
      } finally {
        isRevokingSelection.value = false;
      }
    }

    final selection = SelectableRows(
      rows: rows,
      selectedIds: selectedCodes,
      onRemoveSelection: revokeSelection,
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.only(bottom: context.spacing.space4),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SecretField(
                    key: ValueKey(generatedCodeCard.value),
                    title: "Join Code",
                    description: "Generate a unique join code to invite new members to your organization.",
                    prefix: joinCodeUrlPrefix,
                    onGenerate: () async {
                      final revealed = await ref.executeMembership(
                        ref.membershipCommands.generate(
                          options: joinCodeOptions.value,
                        ),
                        (response) => response.requireAccepted(),
                      );
                      generatedCode.value = revealed.value;
                      return revealed;
                    },
                    generateButtonText: "Generate Join Code",
                    regenerateButtonText: "New Join Code",
                    copyButtonText: "Copy Join Code",
                    copiedSnackbarText: "Join code copied to clipboard",
                  ),
                  SizedBox(height: context.spacing.space2),
                  rolesAsync.when(
                    data: (roles) => JoinCodeSettings(
                      initialOptions: joinCodeOptions.value,
                      availableRoles: roles,
                      onOptionsChanged: (options) =>
                          joinCodeOptions.value = options,
                    ),
                    loading: () => ShimmerBox.rectangle(width: 160, height: 20),
                    error: (error, stack) => ErrorScreen.small(
                      title: "Could not load advanced options",
                      message: error.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsGeometry.symmetric(vertical: 12),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Text(
                  "Active Join Codes",
                  style: theme.textTheme.titleMedium,
                ),
              ),
              PinnedHeaderSliver(
                child: AnimatedPresence(
                  child: selectedCodes.value.isEmpty
                      ? null
                      : BulkJoinCodeActions(
                          selectedCount: selectedCodes.value.length,
                          onRevoke: revokeSelection,
                          onClearSelection: () => selectedCodes.value = {},
                        ),
                ),
              ),
            ],
          ),
        ),
        codesAsync(
          name: "Join Codes",
          builder: (codes) {
            liveCodes.value = codes;
            return context.isDesktop
                ? JoinCodesTable(selection: selection)
                : JoinCodesCardList(selection: selection);
          },
          loading: (_) => const _JoinCodesLoadingShimmer(),
          error: (title, message) => SliverFillRemaining(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space4),
              child: Center(
                child: ErrorScreen(title: title, message: message),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinCodesLoadingShimmer extends StatelessWidget {
  const _JoinCodesLoadingShimmer();

  @override
  Widget build(BuildContext context) => SliverSemantics(
    label: "Loading join codes",
    container: true,
    sliver: context.isDesktop
        ? const _JoinCodesTableShimmer()
        : const _JoinCodesListShimmer(),
  );
}

class _JoinCodesTableShimmer extends StatelessWidget {
  const _JoinCodesTableShimmer();

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Surface(
      color: Surface.colorOf(context),
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
          for (var row = 0; row < 8; row++)
            TableRow(
              children: [
                _ShimmerCell(
                  child: ShimmerBox.rectangle(width: 24, height: 24),
                ),
                _ShimmerCell(
                  child: ShimmerBox.rectangle(width: 180, height: 42),
                ),
                _ShimmerCell(child: ShimmerBox.stadium(width: 76, height: 24)),
                _ShimmerCell(
                  child: ShimmerBox.rectangle(width: 72, height: 14),
                ),
                _ShimmerCell(
                  child: Center(
                    child: ShimmerBox.circle(width: 20, height: 20),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _ShimmerCell extends StatelessWidget {
  const _ShimmerCell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.spacing.space2,
      vertical: context.spacing.space3,
    ),
    child: child,
  );
}

class _JoinCodesListShimmer extends StatelessWidget {
  const _JoinCodesListShimmer();

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              ShimmerBox.rectangle(width: 24, height: 24),
              SizedBox(width: context.spacing.space3),
              ShimmerBox.rectangle(width: 72, height: 14),
            ],
          ),
        ),
      ),
      SliverList.builder(
        itemCount: context.responsive(mobile: 6, tablet: 8),
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: context.spacing.space3),
          child: Surface(
            color: Surface.colorOf(context),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: Row(
                children: [
                  ShimmerBox.circle(width: 40, height: 40),
                  SizedBox(width: context.spacing.space3),
                  Expanded(child: ShimmerBox.rectangle(height: 36)),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
