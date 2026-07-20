part of "route.dart";

class _OrganizationsSelector extends HookWidget {
  const _OrganizationsSelector({required this.organizations});

  final List<OrganizationData> organizations;

  Widget get spacer => const SliverToBoxAdapter(child: SizedBox(height: 16));

  @override
  Widget build(BuildContext context) {
    final searchQuery = useState("");
    final normalizedQuery = searchQuery.value.toLowerCase();
    final filteredOrganizations = organizations.where((organization) {
      return organization.name.toLowerCase().contains(normalizedQuery);
    }).toList();

    final animation = useSliverAnimatedList(
      items: filteredOrganizations,
      identity: (item) => item.organizationId,
      removedItemBuilder: (context, item, animation) =>
          _child(context, item, animation, ignorePointer: true),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverStaggerEntrance(
          sliver: SliverToBoxAdapter(
            child: Text(
              "Select organization",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        spacer,
        SliverStaggerEntrance(
          sliver: SliverToBoxAdapter(
            child: DecoratedTextField(
              decoration: const InputDecoration(
                hintText: "Search Organization",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) => searchQuery.value = query,
            ),
          ),
        ),
        spacer,
        if (filteredOrganizations.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 24),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                title: "No organizations found.",
                description: "Try adjusting your search query.",
              ),
            ),
          )
        else
          SliverAnimatedList(
            key: animation.key,
            initialItemCount: animation.items.length,
            itemBuilder: (context, index, animation) =>
                _child(context, filteredOrganizations[index], animation),
          ),
      ],
    );
  }

  Widget _child(
    BuildContext context,
    OrganizationData item,
    Animation<double> animation, {
    bool ignorePointer = false,
  }) {
    return IgnorePointer(
      key: ValueKey(item.organizationId),
      ignoring: ignorePointer,
      child: ElasticTransition(
        animation: animation,
        child: StaggerEntrance(
          child: _OrganizationListTile(organization: item),
        ),
      ),
    );
  }
}

class _OrganizationListTile extends StatelessWidget {
  const _OrganizationListTile({required this.organization});

  final OrganizationData organization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DepthBox(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () => _openOrganization(context),
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            leading: OrganizationLogo(logoUrl: organization.logoUrl, size: 40),
            title: Text(organization.name.formatted),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ),
      ),
    );
  }

  void _openOrganization(BuildContext context) {
    context.pushRoute(
      OrganizationRoute(organizationId: organization.organizationId.id),
      onFailure: (error) {
        debugPrint("Failed to navigate to organization route: $error");
      },
    );
  }
}
