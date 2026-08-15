import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/main.directories.g.dart";

void main() {
  test("catalog navigation follows source ownership", () {
    expect(
      directories.map((node) => node.name),
      orderedEquals(["app", "features", "shared"]),
    );
  });
}
