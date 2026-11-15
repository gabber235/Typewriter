import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("pressing a choice only some items hold gives it to all, then "
      "takes it from all, then gives each back what it held", (tester) async {
    final written = <List<Set<String>>>[];
    var held = [
      {"writer", "editor"},
      {"reader"},
    ];
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 320,
            child: CheckOptionSet<String>(
              choices: const [
                CheckChoice(key: "writer", label: "Writer"),
                CheckChoice(key: "reader", label: "Reader"),
              ],
              held: held,
              onChanged: (next) => setState(() {
                written.add(next);
                held = next;
              }),
            ),
          ),
        ),
      ),
    );

    expect(find.text("1 of 2"), findsNWidgets(2));
    for (var press = 0; press < 3; press++) {
      await panel.tapOn(find.text("Writer"));
    }

    expect(written, [
      [
        {"writer", "editor"},
        {"reader", "writer"},
      ],
      [
        {"editor"},
        {"reader"},
      ],
      [
        {"editor", "writer"},
        {"reader"},
      ],
    ]);
  });
}
