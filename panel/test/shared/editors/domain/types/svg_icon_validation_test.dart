import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(TypeCatalog(const []));
  final type = NamedType(standardTypeRefs.svgIcon);

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
    const value = StringValue(
      """<svg xmlns="http://www.w3.org/2000/svg"><defs><path id="shape" d="M0 0"/></defs><use href="#shape"/></svg>""",
    );

    expect(value.validateAgainst(type, registry: registry), isEmpty);
  });

  test("SVG validation rejects active script content", () {
    const value = StringValue("<svg><script>alert(1)</script></svg>");

    expect(value.validateAgainst(type, registry: registry), isNotEmpty);
  });

  test("SVG validation rejects event handlers", () {
    const value = StringValue("<svg><path onload=\"run()\"/></svg>");

    expect(value.validateAgainst(type, registry: registry), isNotEmpty);
  });

  test("SVG validation rejects javascript URLs", () {
    const value = StringValue(
      "<svg><a href=\"javascript:run()\"><path/></a></svg>",
    );

    expect(value.validateAgainst(type, registry: registry), isNotEmpty);
  });

  test("SVG validation rejects external URLs", () {
    const value = StringValue(
      "<svg><image href=\"https://example.com/icon.png\"/></svg>",
    );

    expect(value.validateAgainst(type, registry: registry), isNotEmpty);
  });

  test("SVG validation rejects nonfragment CSS URLs", () {
    const value = StringValue(
      "<svg><path style=\"fill:url(https://example.com/fill)\"/></svg>",
    );

    expect(value.validateAgainst(type, registry: registry), isNotEmpty);
  });

  test("SVG validation requires an SVG root", () {
    const value = StringValue("<div>not svg</div>");

    expect(value.validateAgainst(type, registry: registry), isNotEmpty);
  });
}
