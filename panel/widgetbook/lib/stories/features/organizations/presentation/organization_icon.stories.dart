import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An organization logo generated from a seed, or the placeholder an
/// organization without a logo shows.
@widgetbook.UseCase(name: "Default", type: OrganizationLogo)
Widget organizationLogoUseCase(BuildContext context) {
  final placeholder = context.knobs.boolean(label: "No logo");
  final seed = context.knobs.seed();
  return Story(
    const [],
    at: PanelLocation.component(
      Center(
        child: OrganizationLogo(
          logoUrl: placeholder ? null : generateOrganizationIconUrl("$seed"),
          size: context.knobs.double.slider(
            label: "Size",
            initialValue: 40,
            min: 20,
            max: 100,
          ),
          borderRadius: context.knobs.double.slider(
            label: "Border radius",
            initialValue: 8,
            min: 0,
            max: 20,
          ),
        ),
      ),
    ),
  );
}
