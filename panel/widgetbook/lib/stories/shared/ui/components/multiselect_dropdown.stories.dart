import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/presentation/mode_display.dart";
import "package:typewriter_panel/shared/ui/components/multiselect_dropdown.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

class _ColoredItem {
  const _ColoredItem({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ColoredItem && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

@widgetbook.UseCase(name: "Default", type: MultiselectDropdown)
Widget multiselectDropdownDefaultUseCase(BuildContext context) {
  final isEnabled = context.knobs.boolean(label: "Enabled", initialValue: true);

  final items = [
    _ColoredItem(name: "Alpha", color: Colors.red),
    _ColoredItem(name: "Beta", color: Colors.blue),
    _ColoredItem(name: "Gamma", color: Colors.green),
    _ColoredItem(name: "Delta", color: Colors.orange),
    _ColoredItem(name: "Epsilon", color: Colors.purple),
  ];

  return FakeApp(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: Column(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ModeDisplayWidget(),
          for (var i = 0; i < 3; i++)
            HookBuilder(
              builder: (context) {
                final selected = useState<List<_ColoredItem>>([]);
                final focusNode = useFocusNode();

                return MultiselectDropdown<_ColoredItem>(
                  focusNode: focusNode,
                  dropdownMenuEntries: [
                    for (final item in items)
                      DropdownMenuEntry(
                        value: item,
                        label: item.name,
                        style: selected.value.contains(item)
                            ? MenuButtonTheme.of(context).style!.copyWith(
                                backgroundColor: WidgetStateColor.fromMap({
                                  WidgetState.focused: item.color.withValues(
                                    alpha: 0.3,
                                  ),
                                  WidgetState.any: item.color.withValues(
                                    alpha: 0.12,
                                  ),
                                }),
                              )
                            : null,
                        labelWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(item.name),
                          ],
                        ),
                      ),
                  ],
                  selectedItems: selected.value,
                  onSelectionChanged: (items) {
                    selected.value = items;
                  },
                  enabled: isEnabled,
                  itemBuilder: (item) => SmallChip(
                    label: item.name,
                    color: item.color,
                    onDelete: () {
                      selected.value = selected.value
                          .where((i) => i != item)
                          .toList();
                    },
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(name: "With Callbacks", type: MultiselectDropdown)
Widget multiselectDropdownWithCallbacksUseCase(BuildContext context) {
  final items = [
    _ColoredItem(name: "Alpha", color: Colors.red),
    _ColoredItem(name: "Beta", color: Colors.blue),
    _ColoredItem(name: "Gamma", color: Colors.green),
    _ColoredItem(name: "Delta", color: Colors.orange),
    _ColoredItem(name: "Epsilon", color: Colors.purple),
  ];

  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final selected = useState<List<_ColoredItem>>([]);
        final events = useState<List<_CallbackEvent>>([]);
        final focusNode = useFocusNode();

        void addEvent(String action, List<_ColoredItem> items) {
          final event = _CallbackEvent(
            action: action,
            items: items,
            timestamp: DateTime.now(),
          );
          final next = [...events.value, event];
          events.value = next.length > 10
              ? next.sublist(next.length - 10)
              : next;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MultiselectDropdown<_ColoredItem>(
                focusNode: focusNode,
                dropdownMenuEntries: [
                  for (final item in items)
                    DropdownMenuEntry<_ColoredItem>(
                      value: item,
                      label: item.name,
                      style: selected.value.contains(item)
                          ? MenuButtonTheme.of(context).style!.copyWith(
                              backgroundColor: WidgetStateColor.fromMap({
                                WidgetState.focused: item.color.withValues(
                                  alpha: 0.3,
                                ),
                                WidgetState.any: item.color.withValues(
                                  alpha: 0.12,
                                ),
                              }),
                            )
                          : null,
                      labelWidget: Row(
                        spacing: 8,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(item.name),
                        ],
                      ),
                    ),
                ],
                selectedItems: selected.value,
                onSelectionChanged: (items) {
                  final added = items
                      .where((i) => !selected.value.contains(i))
                      .toList();
                  final removed = selected.value
                      .where((i) => !items.contains(i))
                      .toList();

                  if (added.isNotEmpty) {
                    addEvent("Added", added);
                  }
                  if (removed.isNotEmpty) {
                    addEvent("Removed", removed);
                  }

                  selected.value = items;
                },
                itemBuilder: (item) => SmallChip(
                  label: item.name,
                  color: item.color,
                  onDelete: () {
                    selected.value = selected.value
                        .where((i) => i != item)
                        .toList();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          "Event Log",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (events.value.isNotEmpty)
                          TextButton(
                            onPressed: () => events.value = [],
                            child: const Text("Clear"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: events.value.isEmpty
                          ? Center(
                              child: Text(
                                "Select items to see callback events...",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              itemCount: events.value.length,
                              itemBuilder: (context, index) {
                                final event = events
                                    .value[events.value.length - 1 - index];
                                final isAdded = event.action == "Added";
                                final color = isAdded
                                    ? Colors.green
                                    : Colors.red;

                                return TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 300),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Opacity(
                                        opacity: value,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            border: Border.all(
                                              color: color.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isAdded
                                                    ? Icons.add_circle_outline
                                                    : Icons
                                                          .remove_circle_outline,
                                                size: 16,
                                                color: color,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                event.action,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  event.items
                                                      .map((i) => i.name)
                                                      .join(", "),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                _formatTime(event.timestamp),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _CallbackEvent {
  const _CallbackEvent({
    required this.action,
    required this.items,
    required this.timestamp,
  });

  final String action;
  final List<_ColoredItem> items;
  final DateTime timestamp;
}

String _formatTime(DateTime time) {
  return "${time.hour.toString().padLeft(2, '0')}:"
      "${time.minute.toString().padLeft(2, '0')}:"
      "${time.second.toString().padLeft(2, '0')}";
}
