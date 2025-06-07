import "dart:math";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/snackbar.dart";
import "package:typewriter_panel/utils/snake_case_input_formatter.dart";
import "package:typewriter_panel/widgets/generic/components/labeled_divider.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/organization_icon.dart";
import "package:typewriter_panel/widgets/generic/components/retry_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

@RoutePage()
class IndexPage extends HookConsumerWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: organizations.when(
              data: (orgs) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (orgs.isNotEmpty) ...[
                    _OrganizationsSelector(organizations: orgs),
                    SizedBox(height: 24),
                    LabeledDivider()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 300.ms)
                        .slideY(begin: 0.05, end: 0),
                    SizedBox(height: 24),
                  ],
                  _CreateOrganization(),
                ],
              ),
              loading: () => LoadingIndicator(
                message: "Loading organizations...",
              ),
              error: (error, stackTrace) => ErrorScreen(
                title: "Failed to load organizations",
                message: error.toString(),
                child: RetryIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizationsSelector extends HookConsumerWidget {
  const _OrganizationsSelector({required this.organizations});

  final List<OrganizationData> organizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");

    final filteredOrganizations = organizations
        .where(
          (org) =>
              org.name.toLowerCase().contains(searchQuery.value.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select organization",
          style: Theme.of(context).textTheme.headlineMedium,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        SizedBox(height: 16),
        if (organizations.length > 5) ...[
          TextFormField(
            decoration: InputDecoration(
              hintText: "Search Organization",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (query) {
              searchQuery.value = query;
            },
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 16),
        ],
        if (filteredOrganizations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text("No organizations found."),
          )
        else
          SizedBox(
            height: organizations.length >= 5 ? 200 : null,
            child: ListView.builder(
              shrinkWrap: organizations.length < 5,
              itemCount: filteredOrganizations.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final organization = filteredOrganizations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        context.pushRoute(
                          OrganizationRoute(organizationId: organization.id),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: OrganizationIcon(
                          iconUrl: organization.iconUrl,
                          size: 40,
                        ),
                        title: Text(organization.name),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideY(begin: 0.05, end: 0),
          ),
      ],
    );
  }
}

class _CreateOrganization extends HookConsumerWidget {
  const _CreateOrganization();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final randomSeed = useState<String>(Random().nextInt(1000000).toString());

    final iconSeed = nameController.text.isNotEmpty
        ? nameController.text + randomSeed.value
        : randomSeed.value;
    final iconUrl = OrganizationData.generateIconUrl(iconSeed);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Create organisation",
            style: Theme.of(context).textTheme.headlineMedium,
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 400.ms)
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 24),
          SectionTitle(title: "Name")
              .animate()
              .fadeIn(duration: 300.ms, delay: 500.ms)
              .slideY(begin: 0.05, end: 0),
          TextFormField(
            controller: nameController,
            inputFormatters: [
              SnakeCaseInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: "Enter organization name",
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter an organization name.";
              }
              if (value.length < 3) {
                return "Name must be at least 3 characters long.";
              }
              if (!RegExp("^[a-z0-9]").hasMatch(value)) {
                return "Name must start with a lowercase letter or number.";
              }
              if (!RegExp(r"[a-z0-9]$").hasMatch(value)) {
                return "Name must end with a lowercase letter or number.";
              }
              if (!RegExp("^[a-z0-9_]+").hasMatch(value)) {
                return "Name can only contain lowercase letters, numbers, and underscores.";
              }
              if (!RegExp(r"^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$").hasMatch(value)) {
                return "Name must be at least 2 characters, start and end with a letter or number, and only contain underscores in between.";
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 550.ms)
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 24),
          Material(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                randomSeed.value = Random().nextInt(1000000).toString();
              },
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    OrganizationIcon(
                      iconUrl: iconUrl,
                      size: 64,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(title: "Icon"),
                          SizedBox(height: 4),
                          Text(
                            "For now, generated and can be randomized again by clicking the icon.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 650.ms)
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: LoadingButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) {
                  return;
                }
                final navigator = ref.read(appRouterProvider);
                final organizationId = await ref
                    .read(organizationsProvider.notifier)
                    .createOrganization(
                      name: nameController.text,
                      iconUrl: iconUrl,
                    );
                if (organizationId == null) {
                  if (!context.mounted) {
                    return;
                  }
                  showErrorSnackBar(
                    context,
                    "Failed to create organization",
                  );
                  return;
                }
                await navigator.push(
                  OrganizationRoute(
                    organizationId: organizationId,
                  ),
                );
              },
              child: Text("Create"),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 750.ms)
              .slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }
}
