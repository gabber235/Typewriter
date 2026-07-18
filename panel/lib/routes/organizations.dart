part of "route.dart";

class _OrganizationsSelector extends HookWidget {
  const _OrganizationsSelector({required this.organizations});

  final List<OrganizationData> organizations;

  @override
  Widget build(BuildContext context) {
    final searchQuery = useState("");
    final normalizedQuery = searchQuery.value.toLowerCase();
    final filteredOrganizations = organizations.where((organization) {
      return organization.name.toLowerCase().contains(normalizedQuery);
    }).toList();

    final animation = useAnimatedList(
      items: filteredOrganizations,
      identity: (item) => item.organizationId,
      removedItemBuilder: (context, item, animation) =>
          _child(context, item, animation, ignorePointer: true),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggerEntrance(
          child: Text(
            "Select organization",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        if (organizations.length > 5) ...[
          StaggerEntrance(
            child: DecoratedTextField(
              decoration: const InputDecoration(
                hintText: "Search Organization",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) => searchQuery.value = query,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (filteredOrganizations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text("No organizations found."),
          )
        else
          SizedBox(
            height: organizations.length >= 5 ? 200 : null,
            child: AnimatedList(
              key: animation.key,
              shrinkWrap: organizations.length < 5,
              initialItemCount: animation.items.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index, animation) =>
                  _child(context, filteredOrganizations[index], animation),
            ),
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
      child: Material(
        color: Colors.transparent,
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
      OrganizationRoute(
        organizationId: organization.organizationId.key.toString(),
      ),
      onFailure: (error) {
        debugPrint("Failed to navigate to organization route: $error");
      },
    );
  }
}
