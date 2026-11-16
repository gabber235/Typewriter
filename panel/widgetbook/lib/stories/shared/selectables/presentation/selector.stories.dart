import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";
import "package:widgetbook_workspace/support/story_selectable.dart";

@widgetbook.UseCase(name: "Interactive grid", type: Selector)
Widget selectableUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(const SizedBox.expand(child: _SelectorStory())),
  );
}

class _SelectableCard extends HookConsumerWidget {
  const _SelectableCard({required this.selectable});

  final StorySelectableIdentifier selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    return Selector(
      selectableId: selectable,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        final card = AnimatedOpacity(
          opacity: isHovered || isFocused
              ? 0.7
              : isSelected
              ? 1
              : 0.3,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: selectable.color.withValues(alpha: isSelected ? 0.8 : 0.3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: selectable.color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectable.id.formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
        return Semantics(selected: isSelected, child: card);
      },
    );
  }
}

class _SelectorStory extends HookConsumerWidget {
  const _SelectorStory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectables = useState([
      for (final (index, name) in _names.indexed) _selectable(name, index),
    ]);

    return Column(
      children: [
        Padding(
          padding: const .only(right: 16, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [ModeDisplayWidget()],
          ),
        ),
        Expanded(
          child: InspectorScaffold(
            margin: EdgeInsets.only(top: 8, right: 8),
            child: Pane(
              id: "boxes",
              borderRadius: BorderRadius.circular(12),
              margin: EdgeInsets.only(top: 8, left: 8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Section(
                      margin: EdgeInsets.zero,
                      child: Center(
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: List.generate(
                            selectables.value.length,
                            (index) => _SelectableCard(
                              selectable: selectables.value[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: context.spacing.space2,
                    bottom: context.spacing.space2,
                    child: Button(
                      face: ButtonFace.floating,
                      icon: const Icon(Icons.add),
                      label: "Add page",

                      onPressed: () {
                        final count = selectables.value.length;
                        selectables.value = [
                          ...selectables.value,
                          _selectable("Page ${count + 1}", count),
                        ];
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ActionRow(),
      ],
    );
  }
}

const _names = ["Meet the Mayor", "Village Market", "Lost Lantern"];

const _colors = [Colors.indigo, Colors.teal, Colors.deepOrange, Colors.purple];

StorySelectableIdentifier _selectable(String name, int index) =>
    StorySelectableIdentifier(
      id: name.snakeCase(),
      color: _colors[index % _colors.length],
    );
