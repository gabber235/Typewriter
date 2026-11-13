part of "app_router.dart";

enum _AccessDenial { invalidRoute, notAMember, membershipRemoved }

/// Defers access denial redirects until navigation and widget build are stable.
///
/// Multiple guard callbacks can observe the same denial. One scheduled callback
/// owns the redirect and optional explanation, preventing duplicate navigation
/// and toasts.
final class _IndexRedirectCoordinator {
  bool _scheduled = false;

  void schedule(
    StackRouter router, {
    required bool Function() shouldRedirect,
    _AccessDenial? reason,
  }) {
    if (_scheduled) return;
    _scheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // A refused navigation can leave the index alone on the stack, its
        // address still the refused one; that user still needs the index
        // address and the reason.
        final onIndex =
            router.stack.length == 1 && router.topRoute.name == IndexRoute.name;
        if (!shouldRedirect() && !onIndex) return;
        await router.root.replaceAll([
          const IndexRoute(),
        ], updateExistingRoutes: false);
        if (reason == null) return;
        await WidgetsBinding.instance.endOfFrame;
        final context = router.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          context.reportFailure(_message(reason));
        }
      } finally {
        _scheduled = false;
      }
    });
  }

  String _message(_AccessDenial reason) => switch (reason) {
    _AccessDenial.invalidRoute => "The organization link is invalid.",
    _AccessDenial.notAMember => "You do not have access to this organization.",
    _AccessDenial.membershipRemoved =>
      "You no longer have access to this organization.",
  };
}
