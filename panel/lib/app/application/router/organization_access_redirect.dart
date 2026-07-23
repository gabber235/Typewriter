part of "app_router.dart";

enum _AccessDenial { invalidRoute, notAMember, membershipRemoved }

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
        if (!shouldRedirect()) return;
        await router.root.replaceAll([
          const IndexRoute(),
        ], updateExistingRoutes: false);
        if (reason == null) return;
        await WidgetsBinding.instance.endOfFrame;
        final context = router.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          showErrorSnackBar(context, _message(reason));
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
