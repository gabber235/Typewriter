import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

const _path = "[Shared]/Editors/Components";

@widgetbook.UseCase(name: "Deterministic", type: IconSelector, path: _path)
Widget iconSelectorDeterministicUseCase(BuildContext context) {
  return _story(context, useLiveSearch: false);
}

@widgetbook.UseCase(
  name: "Live Iconify search",
  type: IconSelector,
  path: _path,
)
Widget iconSelectorLiveUseCase(BuildContext context) {
  return _story(context, useLiveSearch: true);
}

Widget _story(BuildContext context, {required bool useLiveSearch}) {
  final initialValue = context.knobs.string(
    label: "Initial value",
    initialValue: "mdi:star",
  );
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final readOnly = context.knobs.boolean(label: "Read only");
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 460,
    min: 280,
    max: 720,
  );
  final resultCount = context.knobs.int.slider(
    label: "Mock result count",
    initialValue: 8,
    min: 1,
    max: _storyIcons.length,
  );

  return FakeApp(
    child: Center(
      child: SizedBox(
        width: width,
        child: _IconSelectorDemo(
          initialValue: initialValue,
          enabled: enabled,
          readOnly: readOnly,
          resultCount: resultCount,
          useLiveSearch: useLiveSearch,
        ),
      ),
    ),
  );
}

class _IconSelectorDemo extends HookWidget {
  const _IconSelectorDemo({
    required this.initialValue,
    required this.enabled,
    required this.readOnly,
    required this.resultCount,
    required this.useLiveSearch,
  });

  final String initialValue;
  final bool enabled;
  final bool readOnly;
  final int resultCount;
  final bool useLiveSearch;

  @override
  Widget build(BuildContext context) {
    final value = useState(initialValue);
    useEffect(() {
      value.value = initialValue;
      return null;
    }, [initialValue]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconSelector(
          value: value.value,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: (next) => value.value = next,
          sourceBuilder: useLiveSearch
              ? null
              : (ref, onSelected) => MockSearchSource(
                  nodes: _storyResults(resultCount),
                  actions: {
                    SelectIconSearchAction: SelectIconSearchAction(onSelected),
                  },
                ),
        ),
        const SizedBox(height: 16),
        Text("Selected: ${value.value}"),
        const SizedBox(height: 8),
        const Text(
          "Keyboard: Enter opens, arrows preview, Enter accepts, Escape restores.",
        ),
      ],
    );
  }
}

List<SearchNode> _storyResults(int count) => _storyIcons
    .take(count)
    .map((id) {
      final parts = id.split(":");
      final payload = IconSearchResultPayload(
        identifier: id,
        name: parts.last,
        collection: parts.first.titleCase(),
      );
      return SearchNode.result(
        result: SearchResult(
          id: id,
          type: iconSearchResultType,
          payload: payload,
          actions: const [SelectIconSearchAction],
          title: payload.name,
          subtitle: payload.collection,
        ),
      );
    })
    .toList(growable: false);

const _storyIcons = [
  "mdi:home",
  "mdi:account",
  "lucide:wand",
  "tabler:map",
  "ph:heart",
  "carbon:settings",
  "game-icons:broad-dagger",
  "material-symbols:castle",
  "fa6-solid:dragon",
  "heroicons:film",
  "bi:music-note",
  "ion:planet",
];
