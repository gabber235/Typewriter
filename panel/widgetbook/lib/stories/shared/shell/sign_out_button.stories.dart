import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [SignOutButton] of the access denied screen; pressing it signs the
/// story's user out of its session.
@widgetbook.UseCase(name: "Default", type: SignOutButton)
Widget signOutButtonUseCase(BuildContext context) {
  return Story([
    signedIn(ada, organization: acme),
  ], at: const PanelLocation.component(SignOutButton()));
}
