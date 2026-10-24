import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

const _svgSource =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"> "
    "<path d=\"M4 4h16v16H4z\" fill=\"currentColor\"/></svg>";

@widgetbook.UseCase(name: "Variants", type: ResourceIcon)
Widget resourceIconVariantsUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown<String>(
    label: "Icon",
    options: const ["Iconify", "SVG", "Unavailable"],
    initialOption: "Iconify",
  );
  final size = context.knobs.double.slider(
    label: "Size",
    initialValue: 32,
    min: 12,
    max: 96,
  );
  final icon = switch (variant) {
    "Iconify" => skir.Icon.wrapIconify("material-symbols:book"),
    "SVG" => skir.Icon.wrapSvg(_svgSource),
    _ => null,
  };
  return FakeApp(
    child: Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.borderSubtle),
        ),
        child: ResourceIcon(
          icon: icon,
          size: size,
          color: const Color(0xff3f51b5),
        ),
      ),
    ),
  );
}
