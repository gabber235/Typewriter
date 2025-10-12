import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: DecoratedTextField)
Widget inputFieldUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final isEnabled = context.knobs.boolean(label: "Enabled", initialValue: true);

  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final first = useFocusNode();
        final second = useFocusNode();
        final third = useFocusNode();
        return Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModeDisplayWidget(),
            for (final node in [first, second, third]) ...[
              DecoratedTextField(
                focusNode: node,
                decoration: InputDecoration(hintText: hint),
                readOnly: !isEnabled,
              ),
            ],
          ],
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: "Error", type: DecoratedTextField)
Widget inputFieldErrorUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final errorText = context.knobs.string(
    label: "Error Text",
    initialValue: "This field is required",
  );

  return FakeApp(
    child: DecoratedTextField(
      focusNode: FocusNode(),
      decoration: InputDecoration(hintText: hint, errorText: errorText),
    ),
  );
}

@widgetbook.UseCase(name: "With Prefix Icon", type: DecoratedTextField)
Widget inputFieldWithPrefixIconUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final icon = context.knobs.object.dropdown(
    label: "Icon",
    options: const [
      Icon(Icons.search),
      Icon(Icons.person),
      Icon(Icons.email),
      Icon(Icons.lock),
    ],
    initialOption: const Icon(Icons.search),
    labelBuilder: (option) => option.icon.toString(),
  );

  return FakeApp(
    child: DecoratedTextField(
      focusNode: FocusNode(),
      decoration: InputDecoration(hintText: hint, prefixIcon: icon),
    ),
  );
}

@widgetbook.UseCase(name: "With Callbacks", type: DecoratedTextField)
Widget inputFieldWithCallbacksUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );

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
          events.value = [...events.value, event];

          // Keep only last 10 events
          if (events.value.length > 10) {
            events.value = events.value.sublist(events.value.length - 10);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedTextField(
              focusNode: focusNode,
              decoration: InputDecoration(hintText: hint),
              onChanged: (value) {
                addEvent("onChanged", value, Colors.blue, Icons.edit);
              },
              onDone: (value) {
                addEvent("onDone", value, Colors.green, Icons.done);
              },
              onSubmitted: (value) {
                addEvent("onSubmitted", value, Colors.orange, Icons.send);
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
                      Icon(Icons.timeline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Event Log",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      if (events.value.isNotEmpty)
                        TextButton(
                          onPressed: () => events.value = [],
                          child: Text("Clear"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: events.value.isEmpty
                        ? Center(
                            child: Text(
                              "Start typing to see callback events...",
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
                                duration: Duration(milliseconds: 300),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 4),
                                        padding: EdgeInsets.all(8),
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
                                                style: TextStyle(
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
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';
}

@widgetbook.UseCase(name: "Multiline", type: DecoratedTextField)
Widget inputFieldMultilineUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final maxLines = context.knobs.object.dropdown(
    label: "Max Lines",
    options: [1, 2, 3, 4, 5],
    initialOption: 3,
  );

  return FakeApp(
    child: DecoratedTextField(
      focusNode: FocusNode(),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    ),
  );
}
