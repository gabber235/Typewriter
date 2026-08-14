import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class DateTimeFields extends HookWidget {
  const DateTimeFields({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.autofocus = false,
    super.key,
  });

  final DateTime value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hourController = useInputFieldController(inputDebugLabel: "Hour");
    final minuteController = useInputFieldController(inputDebugLabel: "Minute");
    final secondController = useInputFieldController(inputDebugLabel: "Second");
    useEffect(() {
      if (autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          hourController.beginInteraction();
        });
      }
      return null;
    }, const []);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: "Time",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icones(MaterialSymbols.schedule_rounded, size: 18),
              const SizedBox(width: 8),
              Text("Time", style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: _TimeFieldLabel("Hour")),
              const SizedBox(width: 28),
              const Expanded(child: _TimeFieldLabel("Minute")),
              const SizedBox(width: 28),
              const Expanded(child: _TimeFieldLabel("Second")),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeNumberField(
                  label: "Hour",
                  value: value.hour,
                  maximum: 23,
                  pageStep: 6,
                  enabled: enabled,
                  inputFieldController: hourController,
                  nextInputFieldController: minuteController,
                  onChanged: (hour) =>
                      onChanged(replaceTimePart(value, hour: hour)),
                ),
              ),
              const _TimeSeparator(key: ValueKey("date_time_separator_1")),
              Expanded(
                child: _TimeNumberField(
                  label: "Minute",
                  value: value.minute,
                  maximum: 59,
                  pageStep: 15,
                  enabled: enabled,
                  inputFieldController: minuteController,
                  nextInputFieldController: secondController,
                  onChanged: (minute) =>
                      onChanged(replaceTimePart(value, minute: minute)),
                ),
              ),
              const _TimeSeparator(key: ValueKey("date_time_separator_2")),
              Expanded(
                child: _TimeNumberField(
                  label: "Second",
                  value: value.second,
                  maximum: 59,
                  pageStep: 15,
                  enabled: enabled,
                  inputFieldController: secondController,
                  onChanged: (second) =>
                      onChanged(replaceTimePart(value, second: second)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeFieldLabel extends StatelessWidget {
  const _TimeFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color;
    return SizedBox(
      width: 28,
      height: 52,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimeSeparatorDot(color: color),
            const SizedBox(height: 4),
            _TimeSeparatorDot(color: color),
          ],
        ),
      ),
    );
  }
}

class _TimeSeparatorDot extends StatelessWidget {
  const _TimeSeparatorDot({required this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const SizedBox.square(dimension: 3),
  );
}

class _TimeNumberField extends HookWidget {
  const _TimeNumberField({
    required this.label,
    required this.value,
    required this.maximum,
    required this.pageStep,
    required this.enabled,
    required this.inputFieldController,
    required this.onChanged,
    this.nextInputFieldController,
  });

  final String label;
  final int value;
  final int maximum;
  final int pageStep;
  final bool enabled;
  final InputFieldController inputFieldController;
  final InputFieldController? nextInputFieldController;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(
      text: value.toString().padLeft(2, "0"),
    );

    void update(int next) {
      if (enabled) onChanged(next.clamp(0, maximum));
    }

    void updateDraft(int next) {
      update(next);
      if (controller.text.length != 2 || nextInputFieldController == null) {
        return;
      }
      inputFieldController.endInteraction();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nextInputFieldController!.beginInteraction();
      });
    }

    return Semantics(
      label: label,
      value: value.toString().padLeft(2, "0"),
      readOnly: !enabled,
      increasedValue: value < maximum ? "${value + 1}" : null,
      decreasedValue: value > 0 ? "${value - 1}" : null,
      onIncrease: enabled && value < maximum ? () => update(value + 1) : null,
      onDecrease: enabled && value > 0 ? () => update(value - 1) : null,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              update(value + 1),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              update(value - 1),
          const SingleActivator(LogicalKeyboardKey.home): () => update(0),
          const SingleActivator(LogicalKeyboardKey.end): () => update(maximum),
          const SingleActivator(LogicalKeyboardKey.pageUp): () =>
              update(value + pageStep),
          const SingleActivator(LogicalKeyboardKey.pageDown): () =>
              update(value - pageStep),
        },
        child: ValidatedTextField<int>(
          key: ValueKey("date_time_${label.toLowerCase()}"),
          value: value,
          controller: controller,
          inputFieldController: inputFieldController,
          name: label.toLowerCase(),
          readOnly: !enabled,
          selectAllOnFocus: true,
          deserialize: (value) => value.toString().padLeft(2, "0"),
          serialize: (draft) {
            final parsed = int.tryParse(draft);
            if (parsed == null || parsed < 0 || parsed > maximum) {
              throw FormatException("Enter a value from 0 to $maximum");
            }
            return parsed;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          textAlign: TextAlign.center,
          onChanged: updateDraft,
          decoration: const InputDecoration(
            hintText: "00",
            prefixIcon: SizedBox.shrink(),
            prefixIconConstraints: BoxConstraints(),
          ),
        ),
      ),
    );
  }
}
