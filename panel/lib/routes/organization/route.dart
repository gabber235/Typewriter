import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/generic/components/custom_appbar.dart";
import "package:typewriter_panel/widgets/generic/components/sidebar.dart";

@RoutePage()
class OrganizationPage extends HookConsumerWidget {
  const OrganizationPage({
    @PathParam("organizationId") required this.organizationId,
    super.key,
  });

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrganizationScaffold(
      child: AutoRouter(),
    );
  }
}

class OrganizationScaffold extends StatelessWidget {
  const OrganizationScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Row(
        children: [
          if (!context.isMobile)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
              child: Sidebar(),
            ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
