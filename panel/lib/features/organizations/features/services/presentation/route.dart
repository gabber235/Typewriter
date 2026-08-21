import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
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
              subtext:
                  "Connect services, then inspect every host and runtime from one workspace.",
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
                      ServicesGrid(services: services, topology: topology),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
