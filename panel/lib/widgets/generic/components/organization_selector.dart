import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/modal_header.dart";
import "package:typewriter_panel/widgets/generic/components/organization_icon.dart";

class OrganizationSelector extends HookConsumerWidget {
  const OrganizationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOrganizationAsync = ref.watch(organizationProvider);

    return selectedOrganizationAsync.when(
      data: (selectedOrganization) => _SelectorButton(
        selectedOrganization: selectedOrganization,
        ref: ref,
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text("Error: $error"),
    );
  }
}

class _SelectorButton extends HookWidget {
  const _SelectorButton({
    required this.selectedOrganization,
    required this.ref,
  });

  final OrganizationData? selectedOrganization;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final link = useRef(LayerLink());

    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: CompositedTransformTarget(
        link: link.value,
        child: InkWell(
          onTap: () => _showOrganizationMenu(context, link.value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedOrganization != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OrganizationIcon(
                      iconUrl: selectedOrganization!.iconUrl,
                      size: 24,
                    ),
                  ),
                Text(
                  selectedOrganization?.name.formatted ?? "Select Organization",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrganizationMenu(BuildContext context, LayerLink link) {
    if (context.isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return UncontrolledProviderScope(
            container: ProviderScope.containerOf(context),
            child: _MobileOrganizationMenu(
              selectedOrganization: selectedOrganization,
            ),
          );
        },
      );
      return;
    }
    Navigator.of(context).push(
      _OrganizationPopupRoute(
        link: link,
        themes: InheritedTheme.capture(
          from: context,
          to: Navigator.of(context).context,
        ),
        child: UncontrolledProviderScope(
          container: ProviderScope.containerOf(context),
          child: _OrganizationMenuContent(
            selectedOrganization: selectedOrganization,
          ),
        ),
      ),
    );
  }
}

class _MobileOrganizationMenu extends StatelessWidget {
  const _MobileOrganizationMenu({
    required this.selectedOrganization,
  });

  final OrganizationData? selectedOrganization;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalHeader(),
            Expanded(
              child: _OrganizationMenuContent(
                selectedOrganization: selectedOrganization,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationPopupRoute extends PopupRoute<void> {
  _OrganizationPopupRoute({
    required this.link,
    required this.child,
    required this.themes,
  });

  final LayerLink link;
  final Widget child;
  final CapturedThemes themes;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 60);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(
      Stack(
        children: [
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            followerAnchor: Alignment.topLeft,
            targetAnchor: Alignment.bottomLeft,
            child: FadeTransition(
              opacity: animation,
              child: Material(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                    maxHeight: 420,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationMenuContent extends HookConsumerWidget {
  const _OrganizationMenuContent({
    required this.selectedOrganization,
  });

  final OrganizationData? selectedOrganization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");
    final organizationsAsync = ref.watch(organizationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(searchQuery: searchQuery),
        Flexible(
          child: organizationsAsync.when(
            data: (organizations) {
              final filteredOrganizations = organizations.where((org) {
                if (searchQuery.value.isEmpty) return true;
                return org.name
                    .toLowerCase()
                    .contains(searchQuery.value.toLowerCase());
              }).toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: _OrganizationsList(
                      organizations: filteredOrganizations,
                    ),
                  ),
                  if (selectedOrganization != null)
                    _OrganizationActions(
                      organization: selectedOrganization!,
                    ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: LoadingIndicator(
                message: "Loading organizations...",
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error loading organizations: $error",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.searchQuery});

  final ValueNotifier<String> searchQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        autofocus: true,
        onChanged: (value) => searchQuery.value = value,
        decoration: InputDecoration(
          hintText: "Search organizations",
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _OrganizationsList extends HookConsumerWidget {
  const _OrganizationsList({
    required this.organizations,
  });

  final List<OrganizationData> organizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            "ORGANIZATIONS",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            itemCount: organizations.length,
            itemBuilder: (context, index) {
              final org = organizations[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  child: ListTile(
                    dense: true,
                    leading: OrganizationIcon(
                      iconUrl: org.iconUrl,
                      size: 32,
                    ),
                    title: Text(
                      org.name.formatted,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                    ),
                    onTap: () {
                      ref.read(appRouterProvider).push(
                            OrganizationRoute(organizationId: org.id),
                          );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrganizationActions extends HookConsumerWidget {
  const _OrganizationActions({
    required this.organization,
  });

  final OrganizationData organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionList(
      title: "Actions",
      actions: [
        ActionItem(
          icon: Icons.settings,
          title: "Organization Settings",
          onTap: () {
            Navigator.of(context).pop();
            ref.read(appRouterProvider).push(
                  OrganizationRoute(organizationId: organization.id),
                );
          },
        ),
        ActionItem(
          icon: Icons.person_add,
          title: "Invite Users",
          onTap: () {
            Navigator.of(context).pop();
            ref.read(appRouterProvider).push(
                  OrganizationRoute(organizationId: organization.id),
                );
          },
        ),
      ],
    );
  }
}

class ActionItem {
  const ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class ActionList extends StatelessWidget {
  const ActionList({
    required this.title,
    required this.actions,
    super.key,
  });

  final String title;
  final List<ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ...actions.map(
          (action) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              leading: Icon(action.icon, size: 16),
              title: Text(
                action.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
              ),
              onTap: action.onTap,
            ),
          ),
        ),
      ],
    );
  }
}
