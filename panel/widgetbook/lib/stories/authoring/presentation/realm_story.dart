import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The Realm a story seeds with `realm(...)` or `realmServing(...)` in the
/// organization `signedIn(ada, organization: acme)` opens.
final storyRealmScope = AuthoringScope(
  organizationId: acme.organizationId,
  realmId: skir.recordId("realm_instance:main"),
);

/// The page of the story Realm that shows [resource], through the real
/// router: its surface, rail and inspector.
PanelLocation realmSurface(skir.ResourceId resource) => PanelLocation.route(
  const RealmRouteTree().surface(
    storyRealmScope,
    SurfaceTarget.resource(routed: resource),
  ),
);

/// Builds a component over the panel's editing of the story Realm, the one
/// every surface of that Realm edits through, for components no route shows
/// on their own.
///
/// Builds nothing until the session resolved and the editing admitted the
/// saved document, so the editing [builder] receives belongs to the signed in
/// user's work, survives the story, and has a document to show.
class RealmEditingScene extends HookConsumerWidget {
  const RealmEditingScene({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    RealmEditing workspace,
    AuthoredResourceCommands commands,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userIdProvider);
    if (user.value == null) return const SizedBox.shrink();
    final workspace = ref.watch(realmEditingProvider(storyRealmScope));
    final commands = ref.watch(
      authoredResourceCommandsProvider(storyRealmScope),
    );
    useListenable(workspace);
    if (workspace.state.working == null) return const SizedBox.shrink();
    return builder(context, workspace, commands);
  }
}
