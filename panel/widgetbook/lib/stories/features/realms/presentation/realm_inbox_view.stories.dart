import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/data/features/publication.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

/// The widths the inbox shows at, by the name a story knob shows: the
/// popup, a phone sheet, and a wide surface.
const _widths = {"Popup": 520.0, "Phone": 320.0, "Wide": 900.0};

/// The realm inbox as it draws one review state: issues, saved changes and
/// the Publish action, or why publishing waits. Resources it names come
/// from the Names knob, so long names show how rows wrap.
@widgetbook.UseCase(name: "Review states", type: RealmInboxView)
Widget realmInboxViewUseCase(BuildContext context) {
  final width = context.knobs.width(_widths);
  final long = context.knobs.boolean(label: "Long names");
  return Story(
    [
      signedIn(ada, organization: acme),
      showcaseRealm(),
      ...context.knobs.traits("Review", storyPublications),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 720,
        child: _InboxView(long: long),
      ),
    ),
  );
}

/// The showcase Realm's live review, naming each resource by its id, or by
/// a long name when [long].
class _InboxView extends ConsumerWidget {
  const _InboxView({required this.long});

  final bool long;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String name(String id) {
      return long
          ? "$id, the remarkably long name of a page that runs past the inbox"
          : id;
    }

    return RealmInboxView(
      state: ref.watch(realmInboxProvider(showcaseScope)),
      work: ref.read(localWorkControllerProvider),
      onClose: () {},
      openLocation: (location) async {},
      resourceLabel: (id) => name(id.value),
      removedLabel: (removed) => name("Removed page"),
    );
  }
}
