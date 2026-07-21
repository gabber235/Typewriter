import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Toggle", type: ElasticSwitcher)
Widget elasticSwitcherToggle(BuildContext context) {
  final first = Container(
    key: const Key("first"),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: const Text("Primary", style: TextStyle(fontWeight: FontWeight.w600)),
  );

  final second = Container(
    key: const Key("second"),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 8),
        Text("Confirmed"),
      ],
    ),
  );

  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final useSecond = useState(false);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElasticSwitcher(child: useSecond.value ? second : first),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Toggle"),
                const SizedBox(width: 8),
                Switch(
                  value: useSecond.value,
                  onChanged: (v) => useSecond.value = v,
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
