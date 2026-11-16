import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A person's name over their email, as member and join request cards show
/// them. A long email ellipsizes once the box is too narrow.
@widgetbook.UseCase(name: "Default", type: PersonSummary)
Widget personSummaryUseCase(BuildContext context) {
  final person = context.knobs.object.dropdown(
    label: "Person",
    options: const ["Name and email", "Long name", "Name only", "Email only"],
    initialOption: "Name and email",
  );
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 320,
    min: 120,
    max: 640,
  );
  final (name, email) = switch (person) {
    "Long name" => (
      "Maximiliana Theodora Wilhelmina von Habsburg Lothringen",
      "maximiliana.theodora.von.habsburg@typewriter.test",
    ),
    "Name only" => ("Grace Hopper", null),
    "Email only" => (null, "grace.hopper@typewriter.test"),
    _ => ("Grace Hopper", "grace.hopper@typewriter.test"),
  };
  return Story(
    const [],
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: PersonSummary(name: name, email: email),
      ),
    ),
  );
}
