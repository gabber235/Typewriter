import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/inspector.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/decorated_text_field.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/selector.dart";
import "package:typewriter_panel/features/organizations/features/services/application/services.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/service.pb.dart";
import "package:typewriter_panel/shared/hooks/loading_button_controller.dart";
import "package:typewriter_panel/shared/ui/components/empty_state.dart";
import "package:typewriter_panel/shared/ui/components/grid_selectable_card.dart";
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";
import "package:typewriter_panel/shared/ui/components/status_indicator.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/ui/components/vertical_clipper.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

const double _serviceCardWidth = 180;
const double _serviceCardAspectRatio = 1.05;

@RoutePage()
class ServicesPage extends HookConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Inspector(
      margin: EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "services",
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.only(
          top: 8,
          left: 8,
          right: context.isMobile ? 8 : 0,
        ),
        child: Section(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                title: "Services",
                subtext:
                    "Services are your connected Typewriter instances: Minecraft servers running the Typewriter plugin (engines), content containers (realms), or both. Enter the registration token displayed in your server console to connect a service to your organization.",
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: const _TokenInput(),
              ),
              Expanded(
                child: servicesAsync(
                  name: "Services",
                  builder: (services) {
                    if (services.isEmpty) {
                      return Center(
                        child: EmptyState(
                          title: "No services connected",
                          description:
                              "Start a server with Typewriter installed and enter the registration token above.",
                          icon: MaterialSymbols.dns,
                        ),
                      );
                    }

                    return ClipPath(
                      clipper: VerticalClipper(additionalWidth: 100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: ResponsiveGridView.builder(
                          gridDelegate: ResponsiveGridDelegate(
                            crossAxisExtent: _serviceCardWidth,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: _serviceCardAspectRatio,
                          ),
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return _ServiceCard(service: service);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenInput extends HookConsumerWidget {
  const _TokenInput();

  bool isValidToken(String token) {
    final regex = RegExp(r"^[A-Z0-9]{10}$");
    return regex.hasMatch(token);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final loadingButtonController = useLoadingButtonController();
    final error = useState<String?>(null);

    Future<void> handleBind() async {
      final token = controller.text.trim();
      if (!isValidToken(token)) {
        error.value = "Token must be 10 uppercase alphanumeric characters";
        return;
      }
      error.value = null;
      await ref.read(servicesProvider.notifier).bindService(token);
      controller.clear();
    }

    void handleChange(String value) {
      if (error.value != null && isValidToken(value.trim())) {
        error.value = null;
      }
    }

    return Surface(
      color: Surface.colorOf(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Connect a Service",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you start a Typewriter server, it will display a registration token. Enter it here to bind the service to this organization.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DecoratedTextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "Enter registration token",
                      prefixIcon: const Icon(Icons.key),
                      errorText: error.value,
                    ),
                    onChanged: handleChange,
                    onSubmitted: loadingButtonController.canTrigger
                        ? (_) => loadingButtonController.trigger()
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                LoadingButton(
                  controller: loadingButtonController,
                  onPressed: handleBind,
                  child: const Text("Connect"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends HookConsumerWidget {
  const _ServiceCard({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final selectableId = ServiceIdentifier(service.serviceId);
    final scope = StackRouterScope.of(context);

    return Selector(
      selectableId: selectableId,
      focusNode: focusNode,
      onDoubleTap: scope != null && service.isOnline
          ? () {
              scope.controller.navigate(
                OrganizationRoute(
                  organizationId: service.organizationId,
                  children: [RealmRoute(realmId: service.serviceId)],
                ),
              );
            }
          : null,
      builder: (isSelected, isFocused, isHovered) {
        return Opacity(
          opacity: service.isOnline
              ? 1
              : isSelected
              ? 0.8
              : 0.5,
          child: GridSelectableCard(
            title: service.displayName,
            baseColor: service.color,
            isSelected: isSelected,
            isFocused: isFocused,
            isHovered: isHovered,
            badgeLabel: service.typeLabel,
            header: Icon(service.icon, size: 32),
            footer: StatusIndicator(
              isOnline: service.isOnline,
              lastSeen: service.lastSeenTime,
              dotColor: _statusDotColor(context, service.isOnline, isSelected),
              textColor: _statusTextColor(
                context,
                service.isOnline,
                isSelected,
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _statusDotColor(BuildContext context, bool isOnline, bool isSelected) {
  return switch ((isOnline, isSelected)) {
    (true, false) => Colors.green,
    (true, true) => Colors.white,
    (false, false) => Colors.grey,
    (false, true) => Surface.colorOf(context).withValues(alpha: 0.7),
  };
}

Color _statusTextColor(BuildContext context, bool isOnline, bool isSelected) {
  final theme = Theme.of(context);
  return switch ((isOnline, isSelected)) {
    (true, _) => Colors.white.withValues(alpha: 0.7),
    (false, false) => theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    (false, true) => Surface.colorOf(context).withValues(alpha: 0.5),
  };
}
