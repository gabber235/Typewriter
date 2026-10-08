import "package:typewriter_panel/typewriter_panel.dart";

/// Organization services workspace.
///
/// The page watches the projected service list for names that include unsaved
/// identity edits, while topology remains an independent live projection. The
/// registration control sends tokens through the canonical service provider;
/// this route only composes loading and error states around both reads.
@RoutePage()
class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(projectedServicesProvider);
    final topologyAsync = ref.watch(organizationTopologyStreamProvider);

    return Pane(
      id: "services",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: "Services",
              subtext: "Connect services, then inspect every host and runtime from one workspace.",
            ),
            Padding(
              padding: EdgeInsets.all(context.spacing.space4),
              child: const RegistrationTokenInput(),
            ),
            Expanded(
              child: servicesAsync(
                name: "Services",
                builder: (services) => topologyAsync(
                  name: "Runtime topology",
                  builder: (topology) =>
                      ServicesGraph(services: services, topology: topology),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
