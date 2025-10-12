import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/app/components/dropdown.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

typedef DecoratedDropdownMenu<T> = Dropdown<T>;

@widgetbook.UseCase(name: "Default", type: DecoratedDropdownMenu)
Widget dropdownDefaultUseCase(BuildContext context) {
  final isEnabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final itemCount = context.knobs.object.dropdown(
    label: "Items",
    options: [3, 5, 10],
    initialOption: 5,
  );

  List<DropdownMenuEntry<int>> buildEntries(int count) {
    return List.generate(
      count,
      (i) => DropdownMenuEntry(value: i, label: "Item ${i + 1}"),
    );
  }

  final entries = buildEntries(itemCount);
  return FakeApp(
    child: Column(
      spacing: 20,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ModeDisplayWidget(),
        for (var i = 0; i < 3; i++)
          HookBuilder(
            builder: (context) {
              final node = useFocusNode();
              final state = useState<int?>(null);
              return Column(
                children: [
                  Dropdown<int>(
                    focusNode: node,
                    enabled: isEnabled,
                    selected: state.value,
                    onSelected: (value) => state.value = value,
                    dropdownMenuEntries: entries,
                  ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: "With Callbacks", type: DecoratedDropdownMenu)
Widget dropdownWithCallbacksUseCase(BuildContext context) {
  final itemCount = context.knobs.object.dropdown(
    label: "Items",
    options: [3, 5, 8],
    initialOption: 5,
  );

  List<DropdownMenuEntry<String>> buildEntries(int count) {
    return List.generate(
      count,
      (i) =>
          DropdownMenuEntry(value: "Value ${i + 1}", label: "Label ${i + 1}"),
    );
  }

  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final events = useState<List<CallbackEvent>>([]);
        final focusNode = useFocusNode();

        void addEvent(String type, String value, Color color, IconData icon) {
          final event = CallbackEvent(
            type: type,
            value: value,
            timestamp: DateTime.now(),
            color: color,
            icon: icon,
          );
          final next = [...events.value, event];
          events.value =
              next.length > 10 ? next.sublist(next.length - 10) : next;
        }

        final entries = buildEntries(itemCount);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedDropdownMenu<String>(
              focusNode: focusNode,
              dropdownMenuEntries: entries,
              onSelected: (value) {
                addEvent(
                  "onSelected",
                  value?.toString() ?? "",
                  Colors.orange,
                  Icons.check,
                );
              },
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
                              "Interact with the dropdown to see callback events...",
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
                              final event =
                                  events.value[events.value.length - 1 - index];
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
                                          color: event.color.withValues(
                                            alpha: 0.1,
                                          ),
                                          border: Border.all(
                                            color: event.color.withValues(
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
                                              event.icon,
                                              size: 16,
                                              color: event.color,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              event.type,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: event.color,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '"${event.value}"',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: "Preselected", type: DecoratedDropdownMenu)
Widget dropdownPreselectedUseCase(BuildContext context) {
  final options = const ["Alpha", "Beta", "Gamma", "Delta"];
  final preselected = context.knobs.object.dropdown<String>(
    label: "Initial Selection",
    options: options,
    initialOption: "Beta",
    labelBuilder: (v) => v,
  );
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);

  final entries = options
      .map((o) => DropdownMenuEntry<String>(value: o, label: o))
      .toList();

  return FakeApp(
    child: DecoratedDropdownMenu<String>(
      focusNode: FocusNode(),
      enabled: enabled,
      selected: preselected,
      dropdownMenuEntries: entries,
    ),
  );
}

class CallbackEvent {
  CallbackEvent({
    required this.type,
    required this.value,
    required this.timestamp,
    required this.color,
    required this.icon,
  });
  final String type;
  final String value;
  final DateTime timestamp;
  final Color color;
  final IconData icon;
}

String _formatTime(DateTime time) {
  return "${time.hour.toString().padLeft(2, '0')}:"
      "${time.minute.toString().padLeft(2, '0')}:"
      "${time.second.toString().padLeft(2, '0')}";
}
