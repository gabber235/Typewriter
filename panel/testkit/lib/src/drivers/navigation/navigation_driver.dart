import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Moving through the panel the way the platform does: the back button and
/// an address the user enters or a link opens.
extension PanelNavigation on PanelDriver {
  /// The router the panel's own controls navigate with, such as a link to
  /// another organization or a reveal after creating a resource.
  AppRouter get router => container.read(appRouterProvider);

  /// The resource whose surface the address shows, or null at the Realm
  /// home and outside a Realm.
  String? get routedResource {
    final resource = path.lastIndexOf("/resource/");
    return resource < 0 ? null : path.substring(resource + "/resource/".length);
  }

  /// Opens [route] the way a link inside the panel does, and lets the panel
  /// react; a confirmation the navigation asks for stays open.
  Future<void> follow(PageRouteInfo route) async {
    unawaited(router.navigate(route));
    await settle();
  }

  /// Presses the platform back button and lets the panel react.
  ///
  /// Does not wait for the navigation to finish, since the panel may first
  /// ask whether to discard work; answer through [PanelDriver.dialog].
  Future<void> back() => _platform(const MethodCall("popRoute"));

  /// Opens [address], such as `/organization/acme/members`, the way the
  /// browser address bar or a link does, and lets the panel react.
  ///
  /// Does not wait for the navigation to finish, since the panel may first
  /// ask whether to discard work; answer through [PanelDriver.dialog].
  Future<void> open(String address) => _platform(
    MethodCall("pushRouteInformation", {"location": address, "state": null}),
  );

  /// Delivers [call] on the navigation channel, the way the platform does.
  Future<void> _platform(MethodCall call) async {
    unawaited(
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(call),
        (_) {},
      ),
    );
    await settle();
  }
}
