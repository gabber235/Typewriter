import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "States", type: ResourceItemChrome)
Widget resourceItemChromeUseCase(BuildContext context) {
  final density = context.knobs.object.dropdown<ResourceItemDensity>(
    label: "Density",
    options: ResourceItemDensity.values,
    initialOption: ResourceItemDensity.row,
    labelBuilder: (value) => value.name,
  );
  final interaction = PresentationInteraction(
    selected: context.knobs.boolean(label: "Selected"),
    hovered: context.knobs.boolean(label: "Hovered"),
    routed: context.knobs.boolean(label: "Routed"),
    dropAccepted: context.knobs.boolean(label: "Drop accepted"),
    dropRejected: context.knobs.boolean(label: "Drop rejected"),
  );
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: density == ResourceItemDensity.card ? 180 : 260,
        height: density == ResourceItemDensity.card ? 220 : null,
        child: PresentationInteractionScope(
          value: interaction,
          child: ResourceItemChrome(
            density: density,
            appearance: ResourceAppearance(
              label: "The Lost Village",
              accent: const Color(0xff3f51b5),
              icon: skir.Icon.wrapIconify("material-symbols:book"),
            ),
          ),
        ),
      ),
    ),
  );
}
