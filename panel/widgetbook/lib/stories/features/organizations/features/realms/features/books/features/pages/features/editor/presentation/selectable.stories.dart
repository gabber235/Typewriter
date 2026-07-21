import "package:faker/faker.dart" hide Color;
import "package:flutter/material.dart" hide Title;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Selectable Boxes", type: SelectableBox)
Widget selectableUseCase(BuildContext context) {
  return const FakeApp(child: SelectableDemo());
}

// Selectable box widget
class SelectableBox extends HookConsumerWidget {
  const SelectableBox({required this.selectable, super.key});

  final TestSelectableIdentifier selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    return Selector(
      selectableId: selectable,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        return AnimatedOpacity(
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
      },
    );
  }
}

// Main demo widget
class SelectableDemo extends HookConsumerWidget {
  const SelectableDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectables = useState(<TestSelectableIdentifier>[]);

    TestSelectableIdentifier generate() {
      final id = faker.person.name().snakeCase();
      final blueprint = ObjectBlueprint(
        fields: {
          "name": DataBlueprint.string(modifiers: [const Modifier.snakeCase()]),
          "count": DataBlueprint.integer(),
        },
      );
      return TestSelectableIdentifier(
        id: id,
        dataBlueprint: blueprint,
        color: safeColors.randomOrNull()!,
        onDelete: () {
          selectables.value = selectables.value
              .where((s) => s.id != id)
              .toList();
        },
      );
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectables.value = List.generate(3, (index) => generate());
      });
      return null;
    }, []);

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
          child: Inspector(
            margin: EdgeInsets.only(top: 8, right: 8),
            child: Pane(
              id: "boxes",
              borderRadius: BorderRadius.circular(12),
              margin: EdgeInsets.only(top: 8, left: 8),
              child: FloatingButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  selectables.value = [...selectables.value, generate()];
                },
                child: Section(
                  margin: EdgeInsets.zero,
                  child: Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: List.generate(
                        selectables.value.length,
                        (index) =>
                            SelectableBox(selectable: selectables.value[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ActionRow(),
      ],
    );
  }
}
