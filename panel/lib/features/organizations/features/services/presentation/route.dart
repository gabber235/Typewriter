import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const double _serviceCardWidth = 180;
const double _serviceCardAspectRatio = 1.05;

@RoutePage()
class ServicesPage extends HookConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Inspector(
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        right: context.spacing.space2,
      ),
      child: Pane(
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
                    "Connect Minecraft servers and content realms to this organization. Enter the registration token shown in your server console to register a service and begin syncing Typewriter content.",
              ),
              Padding(
                padding: EdgeInsets.all(context.spacing.space4),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.space2,
                          vertical: context.spacing.space4,
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
          borderRadius: context.shapes.largeBorderRadius,
        ),
        padding: EdgeInsets.all(context.spacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Connect a Service",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.spacing.space2),
            Text(
              "When you start a Typewriter server, it will display a registration token. Enter it here to bind the service to this organization.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.space4),
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
                SizedBox(width: context.spacing.space3),
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
      onDoubleTap:
          scope != null && service.isOnline && service.organization != null
          ? () {
              scope.controller.navigate(
                OrganizationRoute(
                  organizationId: service.organization!.id,
                  children: [RealmRoute(realmId: service.serviceId.id)],
                ),
              );
            }
          : null,
      builder: (isSelected, isFocused, isHovered) {
        final onColor = service.color.on(context);
        return Opacity(
          opacity: service.isOnline
              ? 1
              : isSelected
              ? 0.8
              : 0.5,
          child: GridSelectableCard(
            title: service.displayName,
            baseColor: service.color,
            onBaseColor: onColor,
            badgeOnColor: onColor,
            isSelected: isSelected,
            isFocused: isFocused,
            isHovered: isHovered,
            badgeLabel: service.label,
            header: Icon(service.icon, size: 32),
            footer: StatusIndicator(
              isOnline: service.isOnline,
              lastSeen: service.lastSeen,
              dotColor: isSelected
                  ? onColor
                  : _statusDotColor(context, service.isOnline),
              textColor: isSelected
                  ? onColor.withValues(alpha: 0.7)
                  : _statusTextColor(context, service.isOnline),
            ),
          ),
        );
      },
    );
  }
}

Color _statusDotColor(BuildContext context, bool isOnline) =>
    isOnline ? context.colors.online : context.colors.offline;

Color _statusTextColor(BuildContext context, bool isOnline) =>
    context.colors.contentSecondary;
