import "dart:math";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/models/organization.pb.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/snackbar.dart";
import "package:typewriter_panel/utils/snake_case_input_formatter.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/organization_icon.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";
import "package:typewriter_panel/widgets/generic/components/countdown_badge.dart";
import "package:typewriter_panel/widgets/generic/components/labeled_divider.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";
import "package:typewriter_panel/widgets/generic/components/simple_scaffold.dart";

@RoutePage()
class IndexPage extends HookConsumerWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);

    final content = Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: organizations(
              name: "organizations",
              builder: (orgs) => Column(
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
                  _JoinOrganization(hasExistingOrgs: orgs.isNotEmpty),
                  SizedBox(height: 24),
                  LabeledDivider()
                      .animate()
                      .fadeIn(
                        duration: 300.ms,
                        delay: orgs.isNotEmpty ? 600.ms : 300.ms,
                      )
                      .slideY(begin: 0.05, end: 0),
                  SizedBox(height: 24),
                  _CreateOrganization(hasExistingOrgs: orgs.isNotEmpty),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (context.isMobile) {
      return SimpleScaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
          actions: [
            const UserMenu(compact: true, expand: false),
            const SizedBox(width: 8),
          ],
        ),
        child: content,
      );
    }

    return Stack(
      children: [
        content,
        const Positioned(left: 8, bottom: 8, child: UserMenu(expand: false)),
      ],
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
            child:
                ListView.builder(
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
                                  OrganizationRoute(
                                    organizationId: organization.organizationId,
                                  ),
                                  onFailure: (error) {
                                    debugPrint(
                                      "Failed to navigate to organization route: $error",
                                    );
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: ListTile(
                                leading: OrganizationIcon(
                                  iconUrl: organization.iconUrl,
                                  size: 40,
                                ),
                                title: Text(organization.name.formatted),
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

class _JoinOrganization extends HookConsumerWidget {
  const _JoinOrganization({required this.hasExistingOrgs});

  final bool hasExistingOrgs;

  static const _inviteLinkPrefix = "https://panel.typewritermc.com/join/";
  static const _maxPendingRequests = 5;

  String _extractCode(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith(_inviteLinkPrefix)) {
      return trimmed.substring(_inviteLinkPrefix.length);
    }
    return trimmed;
  }

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter an invite URL or code.";
    }
    final code = _extractCode(value);
    if (code.isEmpty) {
      return "Invalid invite URL or code.";
    }
    return null;
  }

  Future<void> _handleJoinRequest({
    required BuildContext context,
    required WidgetRef ref,
    required GlobalKey<FormState> formKey,
    required TextEditingController controller,
  }) async {
    if (formKey.currentState?.validate() != true) return;

    final code = _extractCode(controller.text);
    try {
      await ref.read(userJoinRequestsProvider.notifier).requestToJoin(code);
      controller.clear();
      if (!context.mounted) return;
      showSuccessSnackBar(context, "Join request submitted successfully.");
    } on Exception catch (e) {
      if (!context.mounted) return;
      showErrorSnackBar(context, "Failed to submit join request: $e");
    }
  }

  Future<void> _handleCancelRequest({
    required BuildContext context,
    required WidgetRef ref,
    required UserJoinRequest request,
  }) async {
    final confirmed = await showConfirmationDialogue(
      context: context,
      title: "Cancel join request?",
      content:
          "Are you sure you want to cancel your request to join ${request.organizationName.formatted}?",
      confirmText: "Cancel Request",
      confirmIcon: Fa6Solid.xmark,
      onConfirm: () async {
        await ref
            .read(userJoinRequestsProvider.notifier)
            .cancelRequest(request.id);
      },
    );

    if (confirmed && context.mounted) {
      showSuccessSnackBar(context, "Join request canceled.");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final joinRequests = ref.watch(userJoinRequestsProvider);
    final activeRequests = joinRequests.maybeWhen(
      data: (requests) => requests.where((r) => !r.isExpired).toList(),
      orElse: () => <UserJoinRequest>[],
    );

    final hasReachedLimit = activeRequests.length >= _maxPendingRequests;
    final baseDelay = hasExistingOrgs ? 400 : 0;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                "Join organization",
                style: Theme.of(context).textTheme.headlineMedium,
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay),
              )
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 8),
          Text(
                "Enter an invite URL or code to request to join an organization.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay + 50),
              )
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 16),
          Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      enabled: !hasReachedLimit,
                      decoration: InputDecoration(
                        hintText: "Invite URL or code",
                      ),
                      validator: _validateInput,
                      onFieldSubmitted: hasReachedLimit
                          ? null
                          : (_) => _handleJoinRequest(
                              context: context,
                              ref: ref,
                              formKey: formKey,
                              controller: controller,
                            ),
                    ),
                  ),
                  SizedBox(width: 12),
                  LoadingButton.filled(
                    onPressed: hasReachedLimit
                        ? null
                        : () => _handleJoinRequest(
                            context: context,
                            ref: ref,
                            formKey: formKey,
                            controller: controller,
                          ),
                    child: Text("Join"),
                  ),
                ],
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay + 100),
              )
              .slideY(begin: 0.05, end: 0),
          if (hasReachedLimit)
            Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "You have reached the maximum of $_maxPendingRequests pending requests. Please wait for approval or cancel an existing request.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: baseDelay + 150),
                )
                .slideY(begin: 0.05, end: 0),
          if (activeRequests.isNotEmpty || joinRequests.hasError) ...[
            SizedBox(height: 24),
            SectionTitle(title: "Pending requests")
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: baseDelay + 150),
                )
                .slideY(begin: 0.05, end: 0),
            SizedBox(height: 8),
            if (joinRequests.hasError) ...[
              Text(
                    joinRequests.error.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: baseDelay + 150),
                  )
                  .slideY(begin: 0.05, end: 0),
              SizedBox(height: 8),
            ],
            ...activeRequests.asMap().entries.map((entry) {
              final index = entry.key;
              final request = entry.value;
              return _PendingJoinRequestTile(
                    request: request,
                    onCancel: () => _handleCancelRequest(
                      context: context,
                      ref: ref,
                      request: request,
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 300.ms,
                    delay: Duration(
                      milliseconds: baseDelay + 200 + (index * 50),
                    ),
                  )
                  .slideY(begin: 0.05, end: 0);
            }),
          ],
        ],
      ),
    );
  }
}

class _PendingJoinRequestTile extends StatelessWidget {
  const _PendingJoinRequestTile({
    required this.request,
    required this.onCancel,
  });

  final UserJoinRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: OrganizationIcon(
          iconUrl: request.organizationIconUrl,
          size: 40,
        ),
        title: Text(request.organizationName.formatted),
        subtitle: Text(
          "Awaiting approval",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountdownBadge(endDate: request.expiresAt),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: onCancel,
              tooltip: "Cancel request",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOrganization extends HookConsumerWidget {
  const _CreateOrganization({required this.hasExistingOrgs});

  final bool hasExistingOrgs;

  String _buildIconUrl(String name, String seed) {
    final iconSeed = name.isNotEmpty ? name + seed : seed;
    return generateOrganizationIconUrl(iconSeed);
  }

  String? _validateName(String? value) {
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
    if (!RegExp(r"^[a-z0-9_]+$").hasMatch(value)) {
      return "Name can only contain lowercase letters, numbers, and underscores.";
    }
    if (!RegExp(r"^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$").hasMatch(value)) {
      return "Name must be at least 3 characters, start and end with a letter or number, and only contain underscores in between.";
    }
    return null;
  }

  void _randomizeSeed(ValueNotifier<String> seed) {
    seed.value = Random().nextInt(1000000).toString();
  }

  Future<void> _handleCreate({
    required BuildContext context,
    required WidgetRef ref,
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required String seed,
  }) async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    final iconUrl = _buildIconUrl(nameController.text, seed);
    final navigator = ref.read(appRouterProvider);
    final organizationId = await ref
        .read(organizationsProvider.notifier)
        .createOrganization(name: nameController.text, iconUrl: iconUrl);

    if (organizationId == null) {
      if (!context.mounted) return;
      showErrorSnackBar(context, "Failed to create organization");
      return;
    }

    await navigator.push(OrganizationRoute(organizationId: organizationId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final randomSeed = useState<String>(Random().nextInt(1000000).toString());

    final iconUrl = _buildIconUrl(nameController.text, randomSeed.value);

    final baseDelay = hasExistingOrgs ? 700 : 400;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                "Create organization",
                style: Theme.of(context).textTheme.headlineMedium,
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay),
              )
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 24),
          SectionTitle(title: "Name")
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay + 100),
              )
              .slideY(begin: 0.05, end: 0),
          TextFormField(
                controller: nameController,
                inputFormatters: [SnakeCaseInputFormatter()],
                decoration: InputDecoration(
                  hintText: "Enter organization name",
                ),
                validator: _validateName,
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay + 150),
              )
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 24),
          Material(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _randomizeSeed(randomSeed),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        OrganizationIcon(iconUrl: iconUrl, size: 64),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionTitle(title: "Icon"),
                              SizedBox(height: 4),
                              Text(
                                "For now, generated and can be randomized again by clicking the icon.",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay + 250),
              )
              .slideY(begin: 0.05, end: 0),
          SizedBox(height: 32),
          SizedBox(
                width: double.infinity,
                child: LoadingButton.filled(
                  onPressed: () => _handleCreate(
                    context: context,
                    ref: ref,
                    formKey: formKey,
                    nameController: nameController,
                    seed: randomSeed.value,
                  ),
                  child: Text("Create"),
                ),
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: baseDelay + 350),
              )
              .slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }
}
