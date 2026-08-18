import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef DateTimeCalendarChoice = ({int value, String label});

class DateTimeCalendarSelectionGrid extends StatefulWidget {
  const DateTimeCalendarSelectionGrid({
    required this.label,
    required this.items,
    required this.selectedValue,
    required this.columns,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<DateTimeCalendarChoice> items;
  final int selectedValue;
  final int columns;
  final ValueChanged<int> onSelected;

  @override
  State<DateTimeCalendarSelectionGrid> createState() =>
      _DateTimeCalendarSelectionGridState();
}

class _DateTimeCalendarSelectionGridState
    extends State<DateTimeCalendarSelectionGrid> {
  late int _focusedIndex;

  @override
  void initState() {
    super.initState();
    _focusedIndex = _selectedIndex;
  }

  @override
  void didUpdateWidget(covariant DateTimeCalendarSelectionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue ||
        oldWidget.items != widget.items) {
      _focusedIndex = _selectedIndex;
    }
  }

  int get _selectedIndex {
    final index = widget.items.indexWhere(
      (item) => item.value == widget.selectedValue,
    );
    return index < 0 ? 0 : index;
  }

  void _moveFocus(int index) {
    setState(() => _focusedIndex = index.clamp(0, widget.items.length - 1));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(_focusedIndex - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _moveFocus(_focusedIndex + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(_focusedIndex - widget.columns);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(_focusedIndex + widget.columns);
    } else if (key == LogicalKeyboardKey.home) {
      _moveFocus(0);
    } else if (key == LogicalKeyboardKey.end) {
      _moveFocus(widget.items.length - 1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      widget.onSelected(widget.items[_focusedIndex].value);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _handleKey,
    child: Builder(
      builder: (context) {
        final hasFocus = Focus.of(context).hasFocus;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          focusable: true,
          focused: hasFocus,
          label: widget.label,
          value: widget.items[_focusedIndex].label,
          hint: "Use arrow keys to move and Enter to select",
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              childAspectRatio: 2.2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final selected = item.value == widget.selectedValue;
              final focused = hasFocus && index == _focusedIndex;
              return Semantics(
                button: true,
                selected: selected,
                label: item.label,
                child: InkWell(
                  borderRadius: context.shapes.smallBorderRadius,
                  onTap: () => widget.onSelected(item.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      borderRadius: context.shapes.smallBorderRadius,
                      border: Border.all(
                        color: focused
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
