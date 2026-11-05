import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The boot screens [EagerInitialization] shows before the router: waiting
/// on a startup dependency, failing to reach one (with Retry), or the
/// signed in organization page once everything resolved.
@widgetbook.UseCase(name: "Default", type: EagerInitialization)
Widget eagerInitializationUseCase(BuildContext context) {
  return Story([
    signedIn(ada, organization: acme),
    ...context.knobs.traits("Startup", {
      "Ready": const [],
      "Waiting": const [startupPending],
      "Unreachable": [
        unreachableAtStartup(StartupDependency.telemetry, times: 1000),
      ],
    }),
  ]);
}
