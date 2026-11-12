import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates join code generation, live projection display, selection, and
/// bulk revocation for the route. It keeps transient UI intent locally while
/// [OrganizationJoinCodes] remains the owner of server backed code state.
/// Bulk revocation holds over the selected codes of the tab's rows and tries
/// every code; each refusal shows under its row.
class JoinCodesTab extends HookConsumerWidget {
  const JoinCodesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codesAsync = ref.watch(visibleOrganizationJoinCodesProvider);
    // One rows handle per tab, above the data builder: the table, the card
    // list and the bulk bar's revoke hold share it.
    // Generate announces its code here, before or after the code arrives.
    final codeFocus = useRowFocus(debugLabel: "Join codes");
    final rows = useAnimatedRows(
      items: codesAsync.value ?? const <skir.JoinCode>[],
      identity: (code) => code.code,
      ready: codesAsync.hasValue,
      focus: codeFocus,
    );
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedCodes = useState<Set<skir.RecordId>>({});
    final joinCodeOptions = useState(const JoinCodeOptions());
    final liveCodes = useRef<List<skir.JoinCode>>([]);

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

    // The bulk bar's key and Revoke all button hold over the tab's rows.
    final revocation = joinCodeRevocation(
      id: "revoke_bulk_join_codes_key",
      label: "Revoke join codes",
      priority: 2,
      targets: () => selectedCodes.value.intersection({
        for (final code in rows.items) code.code,
      }),
      rows: rows,
    );

    final selection = SelectableRows(rows: rows, selectedIds: selectedCodes);
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
                      final code = await ref.executeMembership(
                        ref.membershipCommands.generate(
                          options: joinCodeOptions.value,
                        ),
                        (response) => response.requireAccepted(),
                      );
                      // The projection may already hold the code; expect
                      // handles both orders.
                      codeFocus.expect(code.code);
                      generatedCode.value = code.code.id;
                      return SecretFieldRevealed(
                        value: code.code.id,
                        expiresAt: code.expiresAt,
                      );
                    },
                    generateButtonText: "Generate Join Code",
                    regenerateButtonText: "New Join Code",
                    copyButtonText: "Copy Join Code",
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
                          revocation: revocation,
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
