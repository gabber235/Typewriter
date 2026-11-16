import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Tag inheritance", type: AuthoredResourceInspection)
Widget tagInheritanceUseCase(BuildContext context) {
  final topology = context.knobs.object.dropdown(
    label: "Topology",
    options: _topologies.keys.toList(),
    initialOption: "Branching",
  );
  final long = context.knobs.boolean(label: "Long names", initialValue: false);
  final subject = context.knobs.object.segmented(
    label: "Inspecting",
    options: const ["Book", "Tag"],
    initialOption: "Book",
  );
  final direction = context.knobs.object.segmented(
    label: "Text direction",
    options: const ["Left to right", "Right to left"],
    initialOption: "Left to right",
  );
  final width = context.knobs.double.slider(
    label: "Inspector width",
    initialValue: 520,
    min: 280,
    max: 700,
  );
  final (tags, roots) = _topologies[topology]!(long: long);
  return Story(
    [
      signedIn(ada, organization: acme),
      realmServing(
        compiledTagInheritanceDocument(
          tags: tags,
          roots: [for (final root in roots) root.tagId],
        ),
      ),
    ],
    at: PanelLocation.component(
      Directionality(
        textDirection: direction == "Right to left"
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: SizedBox(
          width: width,
          height: 760,
          child: RealmEditingScene(
            builder: (context, workspace, commands) => SingleChildScrollView(
              child: AuthoredResourceInspection(
                resource: subject == "Book"
                    ? compiledInheritanceBookId
                    : compiledInheritanceTagId,
                workspace: workspace,
                commands: commands,
                commitPolicy: EditorCommitPolicy.applyResource,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Tag hierarchies by name: the tags and the roots the subject carries,
/// with long names when asked.
final _topologies =
    <String, (List<Tag>, List<Tag>) Function({required bool long})>{
      "Leaf": ({required long}) {
        final quest = _tag("Quest", long);
        return ([quest], [quest]);
      },
      "Chain": ({required long}) {
        final region = _tag("Region", long);
        final village = _tag("Village", long, parents: [region]);
        final quest = _tag("Quest", long, parents: [village]);
        return ([quest, village, region], [quest]);
      },
      "Branching": ({required long}) {
        final story = _tag("Story", long);
        final region = _tag("Region", long);
        final quest = _tag("Quest", long, parents: [story, region]);
        return ([quest, story, region], [quest]);
      },
      "Shared ancestor": ({required long}) {
        final story = _tag("Story", long);
        final region = _tag("Region", long);
        final village = _tag("Village", long, parents: [story, region]);
        final quest = _tag("Quest", long, parents: [village]);
        final errand = _tag("Errand", long, parents: [village]);
        return ([quest, errand, village, story, region], [quest, errand]);
      },
    };

Tag _tag(String name, bool long, {List<Tag> parents = const []}) {
  final shown = long ? "$name of the northern highlands" : name;
  return Tag(
    tagId: skir.ResourceId(value: "tag:${name.snakeCase()}"),
    name: shown,
    color: switch (name) {
      "Quest" || "Errand" => const Color(0xffff527d),
      "Region" => const Color(0xff67d9ae),
      _ => const Color(0xff69a9ff),
    },
    parentIds: [for (final parent in parents) parent.tagId],
    placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  );
}
