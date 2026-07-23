import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodesTab extends HookConsumerWidget {
  const JoinCodesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codesAsync = ref.watch(organizationJoinCodesProvider);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedCodes = useState<Set<skir.RecordId>>({});
    final joinCodeOptions = useState(const JoinCodeOptions());
    final liveCodes = useRef<List<OrganizationJoinCode>>([]);
    final isRevokingSelection = useRef(false);

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
          content:
              "Are you sure you want to revoke these join codes? They will no longer work.",
          confirmText: "Revoke All",
          confirmIcon: Fa6Solid.link_slash,
          onConfirm: () async {
            for (final code in codesToRevoke) {
              await ref
                  .read(organizationJoinCodesProvider.notifier)
                  .revokeCode(code);
            }
            selectedCodes.value = {};
          },
        );
      } finally {
        isRevokingSelection.value = false;
      }
    }

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
                    title: "Join Code",
                    description:
                        "Generate a unique join code to invite new members to your organization.",
                    prefix: joinCodeUrlPrefix,
                    onGenerate: () => ref
                        .read(organizationJoinCodesProvider.notifier)
                        .generateCode(options: joinCodeOptions.value),
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
                child: AnimatedSize(
                  duration: 800.ms,
                  alignment: Alignment.topLeft,
                  curve: ElasticOutCurve(0.9),
                  child: AnimatedSwitcher(
                    duration: 400.ms,
                    child: selectedCodes.value.isEmpty
                        ? const SizedBox.shrink()
                        : BulkJoinCodeActions(
                            selectedCount: selectedCodes.value.length,
                            onRevoke: revokeSelection,
                            onClearSelection: () => selectedCodes.value = {},
                          ),
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
            return SliverStaggerScope(
              sliver: context.isDesktop
                  ? JoinCodesTable(
                      codes: codes,
                      selectedCodes: selectedCodes,
                      onRevokeSelection: revokeSelection,
                    )
                  : JoinCodesCardList(
                      codes: codes,
                      selectedCodes: selectedCodes,
                      onRevokeSelection: revokeSelection,
                    ),
            );
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
  Widget build(BuildContext context) => context.isDesktop
      ? const _JoinCodesTableShimmer(key: ValueKey("joinCodesLoadingDesktop"))
      : const _JoinCodesListShimmer(key: ValueKey("joinCodesLoadingMobile"));
}

class _JoinCodesTableShimmer extends StatelessWidget {
  const _JoinCodesTableShimmer({super.key});

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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: child,
  );
}

class _JoinCodesListShimmer extends StatelessWidget {
  const _JoinCodesListShimmer({super.key});

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              ShimmerBox.rectangle(width: 24, height: 24),
              SizedBox(width: 12),
              ShimmerBox.rectangle(width: 72, height: 14),
            ],
          ),
        ),
      ),
      SliverList.builder(
        itemCount: context.responsive(mobile: 6, tablet: 8),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Surface(
            color: Surface.colorOf(context),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: Row(
                children: [
                  ShimmerBox.circle(width: 40, height: 40),
                  SizedBox(width: 12),
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
