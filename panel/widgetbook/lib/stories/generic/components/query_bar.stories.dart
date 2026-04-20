import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/generic/components/query_bar.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: QueryBar)
Widget queryBarDefaultUseCase(BuildContext context) {
  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final query = useState(
          context.knobs.string(label: "Query", initialValue: ""),
        );
        final selectors = useMemoized(() => mockQuerySelectors, const []);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: QueryBar(
              query: query.value,
              selectors: selectors,
              onQueryChanged: (next) => query.value = next,
            ),
          ),
        );
      },
    ),
  );
}
