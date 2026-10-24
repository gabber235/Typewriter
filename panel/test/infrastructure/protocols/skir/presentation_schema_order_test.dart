import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final sourceFile = File("../skir-src/editor/v1/presentation.skir");
  final skipReason = sourceFile.existsSync()
      ? false
      : "The canonical Skir source is outside this test workspace.";

  test("presentation record identifiers ascend in file order", () {
    final source = sourceFile.readAsStringSync();
    final identifiers = RegExp(
      r"^(?:struct|enum) [^(]+\(810800([0-9]{3})\)",
      multiLine: true,
    ).allMatches(source).map((match) => int.parse(match.group(1)!)).toList();

    expect(identifiers, isNotEmpty);
    expect(
      identifiers,
      List.generate(identifiers.length, (index) => index + 1),
    );
  }, skip: skipReason);

  test("presentation element ordinals ascend in declaration order", () {
    final source = sourceFile.readAsStringSync();
    final body = RegExp(
      r"enum PresentationElement\(810800[0-9]{3}\) \{([\s\S]+?)\n\}",
    ).firstMatch(source)!.group(1)!;
    final ordinals = RegExp(
      r"= ([0-9]+);$",
      multiLine: true,
    ).allMatches(body).map((match) => int.parse(match.group(1)!)).toList();

    expect(ordinals, List.generate(ordinals.length, (index) => index + 1));
  }, skip: skipReason);
}
