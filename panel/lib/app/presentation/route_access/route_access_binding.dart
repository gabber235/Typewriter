import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/access/route_access_coordinator.dart";
import "package:typewriter_panel/app/presentation/route_access/authentication_route_access_binding.dart";
import "package:typewriter_panel/app/presentation/route_access/organization_route_access_binding.dart";

final class RouteAccessBinding extends ConsumerStatefulWidget {
  const RouteAccessBinding({
    required this.access,
    required this.builder,
    super.key,
  });

  final RouteAccessCoordinator access;
  final WidgetBuilder builder;

  @override
  ConsumerState<RouteAccessBinding> createState() => _RouteAccessBindingState();
}

final class _RouteAccessBindingState extends ConsumerState<RouteAccessBinding> {
  List<ProviderSubscription<Object?>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(RouteAccessBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.access == widget.access) return;
    _closeSubscriptions();
    _bind();
  }

  void _bind() {
    _subscriptions = [
      bindAuthenticationRouteAccess(ref, widget.access.authentication),
      bindOrganizationRouteAccess(ref, widget.access.organizations),
    ];
  }

  void _closeSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _subscriptions = [];
  }

  @override
  void dispose() {
    _closeSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
