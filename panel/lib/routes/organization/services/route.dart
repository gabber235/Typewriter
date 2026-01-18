import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/services.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/empty_state.dart";
import "package:typewriter_panel/widgets/generic/components/grid_selectable_card.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";

@RoutePage()
class ServicesPage extends HookConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final servicesAsync = ref.watch(servicesProvider);

    final paddingAmount = context.responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Pane(
      id: "services",
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.only(
        top: 8,
        left: 8,
        right: context.isDesktop ? 0 : 8,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeading(
                title: "Services",
                subtext:
                    "Connect your Minecraft servers to this organization. Enter a registration token to bind a service.",
                padding: EdgeInsets.all(paddingAmount),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingAmount),
                child: const _TokenInput(),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingAmount),
                child: servicesAsync(
                  name: "Services",
                  shrink: true,
                  builder: (services) {
                    if (services.isEmpty) {
                      return EmptyState(
                        title: "No services connected",
                        description:
                            "Start a server with TypeWriter installed and enter the registration token above.",
                        icon: MaterialSymbols.dns,
                      );
                    }
                    return _ServicesGrid(services: services);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenInput extends HookConsumerWidget {
  const _TokenInput();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useTextEditingController();
    final focusNode = useFocusNode();

    Future<void> handleBind() async {
      final token = controller.text.trim();
      if (token.isEmpty) return;

      await ref.read(servicesProvider.notifier).bindService(token);
      controller.clear();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
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
            "When you start a TypeWriter server, it will display a registration token. Enter it here to bind the service to this organization.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Enter registration token",
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onSubmitted: (_) => handleBind(),
                ),
              ),
              const SizedBox(width: 12),
              LoadingButton(
                onPressed: handleBind,
                child: const Text("Connect"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends HookWidget {
  const _ServicesGrid({required this.services});

  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final service in services)
          _ServiceCard(service: service, theme: theme),
      ],
    );
  }
}

class _ServiceCard extends HookConsumerWidget {
  const _ServiceCard({required this.service, required this.theme});

  final Service service;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final selectableId = ServiceIdentifier(service.id);

    return Selector(
      selectableId: selectableId,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        return GridSelectableCard(
          title: service.displayName,
          baseColor: theme.colorScheme.primary,
          isSelected: isSelected,
          isFocused: isFocused,
          isHovered: isHovered,
          badgeLabel: service.typeLabel,
          header: Icon(
            service.icon,
            size: 32,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
          footer: _StatusIndicator(
            isOnline: service.isOnline,
            lastSeenLabel: service.lastSeenLabel,
            isSelected: isSelected,
          ),
        );
      },
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.isOnline,
    required this.lastSeenLabel,
    required this.isSelected,
  });

  final bool isOnline;
  final String lastSeenLabel;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isOnline ? Colors.green : Colors.grey;
    final textColor = isSelected
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isOnline ? "Online" : lastSeenLabel,
          style: TextStyle(fontSize: 11, color: textColor),
        ),
      ],
    );
  }
}
