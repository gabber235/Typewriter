import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/access/access.dart";
import "package:typewriter_panel/app/presentation/route_access/authentication_route_access_binding.dart";
import "package:typewriter_panel/app/presentation/route_access/organization_route_access_binding.dart";

/// Binds provider state to the route access coordinator used by the router.
///
/// The binding owns the two provider subscriptions for its [access] instance.
/// It seeds both modules immediately, rebinds when the coordinator changes,
/// and closes subscriptions before the widget is disposed. The child builder
/// is rendered after the initial synchronous callbacks have populated access.
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

  /// Starts subscriptions for the coordinator's authentication and membership
  /// modules. Each binding uses an immediate callback to avoid an uninitialized
  /// route decision during the first router build.
  void _bind() {
    _subscriptions = [
      bindAuthenticationRouteAccess(ref, widget.access.authentication),
      bindOrganizationRouteAccess(ref, widget.access.organizations),
    ];
  }

  /// Detaches every subscription owned by the current coordinator binding.
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
