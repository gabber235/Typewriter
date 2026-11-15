import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The organization's settings: its name, its icon and deleting it.
///
/// The name saves on its own after editing and the icon saves when a new one
/// is rolled. Deleting is a permanent hold that only the founder may start;
/// it lists what goes with the organization, counted live, before the hold.
@RoutePage()
class OrganizationSettingsPage extends ConsumerWidget {
  const OrganizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organization = ref.watch(organizationProvider);
    return Pane(
      id: "organization_settings",
      primary: true,
      openFocus: PaneOpenFocus.firstItem,
      child: Section(
        margin: EdgeInsets.zero,
        child: CustomScrollView(
          primary: true,
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeading(
                title: "Settings",
                subtext: "The name and icon of this organization.",
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(context.spacing.space6),
              sliver: SliverToBoxAdapter(
                child: organization(
                  name: "organization",
                  builder: (organization) => organization == null
                      ? const SizedBox.shrink()
                      : OrganizationSettings(organization: organization),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three settings sections of [organization], as the signed in user may
/// use them.
class OrganizationSettings extends ConsumerWidget {
  const OrganizationSettings({required this.organization, super.key});

  final skir.Organization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider).value;
    final footprint = ref.watch(organizationFootprintProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.spacing.space8,
        children: [
          Enter(
            token: MotionToken.loadIn,
            child: OrganizationNameSection(organization: organization),
          ),
          Enter(
            token: MotionToken.loadIn,
            child: OrganizationIconSection(organization: organization),
          ),
          Enter(
            token: MotionToken.loadIn,
            child: OrganizationDeleteSection(
              organization: organization,
              footprint: footprint,
              founder: organization.foundedBy(userId),
            ),
          ),
        ],
      ),
    );
  }
}

/// The organization's name, saved on its own after editing. A refusal, such
/// as a name another organization uses, stays under the field.
class OrganizationNameSection extends HookConsumerWidget {
  const OrganizationNameSection({required this.organization, super.key});

  final skir.Organization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = organization.organizationId;
    final container = ProviderScope.containerOf(context, listen: false);
    final bindings = useMemoized(
      () =>
          InspectionBindings(workspace: ref.read(localWorkControllerProvider)),
      [id],
    );
    useEffect(() => bindings.dispose, [bindings]);
    final registration = organizationIdentityTarget(
      organization: organization,
      organizations: ref.read(organizationsProvider.notifier),
      // The editor may save after this section leaves, so it reads the
      // organizations through the container, which outlives the widget.
      current: () => container.read(organizationsProvider.future),
      work: ref.read(localWorkProvider.notifier),
    );
    final owner = bindings.editor(registration);
    final host = useMemoized(
      () => organizationIdentityPresentationHost(owner: owner),
      [owner],
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

/// The organization's icon; rolling a new one saves it straight away.
class OrganizationIconSection extends ConsumerWidget {
  const OrganizationIconSection({required this.organization, super.key});

  final skir.Organization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = organization.logoUrl;
    return OrganizationIconPicker(
      iconUrl: logo.isEmpty ? null : logo,
      description: "Press the icon to roll a new one. It saves straight away.",
      onRandomize: () => ref.changeOrganizationIcon(
        organization.organizationId,
        randomOrganizationIconUrl(organization.name),
      ),
    );
  }
}

/// What deleting [organization] takes with it, and the permanent hold that
/// deletes it. Only the [founder] may hold it; everyone else sees why not.
class OrganizationDeleteSection extends ConsumerWidget {
  const OrganizationDeleteSection({
    required this.organization,
    required this.footprint,
    required this.founder,
    super.key,
  });

  final skir.Organization organization;

  /// The live counts of what goes with it, or null while they arrive.
  final OrganizationFootprint? footprint;

  /// Whether the signed in user founded the organization.
  final bool founder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final command = deleteOrganizationCommand(organization);
    final button = CommandButton(
      command: command,
      face: ButtonFace.outlined,
      color: context.colors.danger,
      icon: Icones(MaterialSymbols.delete_forever_rounded, size: 20),
      label: "Delete organization",
      hint: "Destructive",
      enabled: founder,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space3,
      children: [
        const SectionTitle(title: "Delete organization"),
        OrganizationFootprintList(footprint: footprint),
        if (founder)
          ManagedActionSet(shortcuts: [command], child: button)
        else ...[
          button,
          Text(onlyFounderDeletes, style: context.text.sentence),
        ],
      ],
    );
  }
}

/// What deleting the organization takes with it, one consequence per line,
/// counted live; a skeleton of the same lines while the counts arrive.
class OrganizationFootprintList extends StatelessWidget {
  const OrganizationFootprintList({required this.footprint, super.key});

  final OrganizationFootprint? footprint;

  @override
  Widget build(BuildContext context) {
    final counts = footprint;
    final lines = [
      (
        MaterialSymbols.groups_rounded,
        counts == null
            ? null
            : "${_count(counts.members, "member", "members")} "
                  "${counts.members == 1 ? "loses" : "lose"} access.",
      ),
      (
        MaterialSymbols.link_off_rounded,
        counts == null
            ? null
            : "${_count(counts.services, "service is", "services are")} "
                  "unbound and keep running, with their realms.",
      ),
      (
        MaterialSymbols.key,
        counts == null
            ? null
            : "${_count(counts.joinCodes, "join code", "join codes")} "
                  "${counts.joinCodes == 1 ? "stops" : "stop"} working.",
      ),
      (
        MaterialSymbols.badge_rounded,
        counts == null
            ? null
            : "${_count(counts.roles, "role is", "roles are")} removed.",
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space2,
      children: [
        for (final (icon, text) in lines)
          Row(
            spacing: context.spacing.space2,
            children: [
              Icones(icon, size: 16, color: context.colors.contentSecondary),
              Expanded(
                child: text == null
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: ShimmerBox.rectangle(width: 240, height: 16),
                      )
                    : MotionLabel(text, style: context.text.sentence),
              ),
            ],
          ),
      ],
    );
  }

  static String _count(int count, String one, String many) =>
      "$count ${count == 1 ? one : many}";
}

/// The one Delete organization command for [organization]: a permanent hold
/// on D, Delete or Backspace and on its button, which lands on the
/// organization list once the organization is gone.
ActionShortcut deleteOrganizationCommand(skir.Organization organization) {
  return ActionShortcut.intent(
    id: "delete_organization_${organization.organizationId.id}",
    label: "Delete organization",
    description: "Delete this organization for everyone",
    intent: DeleteIntent,
    priority: 1,
    run: ActionRun.hold(
      HoldPlan<skir.RecordId>.all(
        weight: HoldWeight.permanent,
        verb: "Delete",
        doneWord: "Deleted",
        targets: (_) => {organization.organizationId},
        outcome: (_) =>
            "Delete ${organization.name}? Nothing can bring it back.",
        work: (ref, targets) async {
          final router = ref.read(navigationRouterProvider);
          try {
            await ref.deleteOrganizations(targets);
          } on RefusedTargets catch (refused) {
            throw HoldRefused(refused.message);
          }
          await router.replaceAll([const IndexRoute()]);
        },
      ),
    ),
  );
}
