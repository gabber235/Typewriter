import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The scope of the showcase realm stories.
final realmShowcaseScope = AuthoringScope(
  organizationId: skir.recordId("organization:showcase"),
  realmId: skir.recordId("realm:showcase"),
);

/// Opens the showcase realm with [routed] as the routed resource.
class RealmShowcaseStory extends StatelessWidget {
  const RealmShowcaseStory({
    required this.routed,
    required this.child,
    super.key,
  });

  final skir.ResourceId routed;
  final Widget child;

  @override
  Widget build(BuildContext context) => AuthoringFixtureApp(
    scenario: routed,
    createDocument: fixtureRealmShowcase,
    overrides: [
      organizationIdProvider.overrideWithValue(
        realmShowcaseScope.organizationId,
      ),
      realmIdProvider.overrideWithValue(realmShowcaseScope.realmId),
      routedResourceIdProvider.overrideWithValue(routed),
    ],
    child: child,
  );
}
