import "package:typewriter_panel/typewriter_panel.dart";

/// The owner chain of the routed resource below the realm root, one crumb per
/// resource. Each crumb lists its siblings, so another Book or page is one
/// choice away.
class ResourceBreadcrumbs extends ConsumerWidget {
  const ResourceBreadcrumbs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    if (scope == null) return const SizedBox.shrink();
    final crumbs = ref.watch(resourceBreadcrumbsProvider(scope));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, crumb) in crumbs.indexed) ...[
          if (index > 0)
            Icon(
              Icons.chevron_right,
              size: 16,
              color: context.colors.contentDisabled,
            ),
          ResourceCrumbSelector(scope: scope, crumb: crumb),
        ],
      ],
    );
  }
}

/// One crumb: the resource it shows, and the resources it can switch to.
class ResourceCrumbSelector extends ConsumerWidget {
  const ResourceCrumbSelector({
    required this.scope,
    required this.crumb,
    super.key,
  });

  final AuthoringScope scope;
  final ResourceCrumb crumb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = crumb.siblings.firstWhereOrNull(
      (choice) => choice.resource == crumb.resource,
    );
    return SelectorPopupWithSelection<ResourceCrumbChoice>(
      itemsAsync: AsyncData(crumb.siblings),
      selectedAsync: AsyncData(current),
      name: "resources",
      buttonBuilder: (selected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResourceIcon(
            icon: selected?.appearance.icon,
            size: 16,
            color:
                selected?.appearance.accent ?? context.colors.contentDisabled,
          ),
          SizedBox(width: context.spacing.space2),
          Text(
            selected?.appearance.label ?? "Resource",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      contentBuilder: (choices, selected, onDismiss) => _CrumbMenu(
        choices: choices,
        selected: selected,
        onChoose: (choice) {
          onDismiss(choice);
          ref.read(realmSurfaceNavigationProvider).open(scope, choice.resource);
        },
      ),
    );
  }
}

class _CrumbMenu extends HookWidget {
  const _CrumbMenu({
    required this.choices,
    required this.selected,
    required this.onChoose,
  });

  final List<ResourceCrumbChoice> choices;
  final ResourceCrumbChoice? selected;
  final ValueChanged<ResourceCrumbChoice> onChoose;

  @override
  Widget build(BuildContext context) {
    final searchQuery = useState("");
    final query = searchQuery.value.toLowerCase();
    final filtered = choices
        .where(
          (choice) => choice.appearance.label.toLowerCase().contains(query),
        )
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorSearchField(searchQuery: searchQuery, hintText: "Search"),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final choice = filtered[index];
              return ListTile(
                dense: true,
                selected: choice.resource == selected?.resource,
                leading: ResourceIcon(
                  icon: choice.appearance.icon,
                  color: choice.appearance.accent,
                  size: 20,
                ),
                title: Text(choice.appearance.label),
                onTap: () => onChoose(choice),
              );
            },
          ),
        ),
        SizedBox(height: context.spacing.space2),
      ],
    );
  }
}
