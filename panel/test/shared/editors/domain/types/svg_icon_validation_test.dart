import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("icon values expose their concrete nominal representation", () {
    const iconify = IconValue.iconify("fa-solid:star");
    const svg = IconValue.svg('<svg viewBox="0 0 1 1"></svg>');

    expect(iconify.validate(), isEmpty);
    expect(svg.validate(), isEmpty);
    expect(iconify.typedValue.concreteType, standardTypeRefs.iconifyIcon);
    expect(svg.typedValue.concreteType, standardTypeRefs.svgIcon);
  });

  test("icon values reject unsafe SVG payloads", () {
    const icon = IconValue.svg('<svg><script>alert("x")</script></svg>');

    expect(icon.validate().single.code, TypeDiagnosticCode.invalidValue);
  });

  test("sanitized SVG allows its standard namespace and fragment links", () {
    const icon = IconValue.svg(
      """<svg xmlns="http://www.w3.org/2000/svg"><defs><path id="shape" d="M0 0"/></defs><use href="#shape"/></svg>""",
    );

    expect(icon.validate(), isEmpty);
  });
}
