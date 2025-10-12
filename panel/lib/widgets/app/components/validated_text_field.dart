import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/utils/object.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

/// The current state of the duration editor
class _State {
  const _State();
}

const _Initial _initial = _Initial();

class _Initial extends _State {
  const _Initial();
}

class _Invalid extends _State {
  const _Invalid(this.message);

  final String message;
}

class _Valid<T> extends _State {
  const _Valid(this.value, this.message);

  final T value;
  final String message;
}

class ValidatedTextField<T> extends HookConsumerWidget {
  const ValidatedTextField({
    required this.value,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.name = "",
    this.icon = Ic.round_text_fields,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.keepValidVisibleWhileFocused = false,
    this.keepErrorVisibleWhenUnfocused = true,
    this.deserialize,
    this.serialize,
    this.formatted,
    this.validator,
    this.onChanged,
    this.onDone,
    this.onEditingComplete,
    this.onSubmitted,
    this.actions,
    this.textFieldActions,
    this.surroundingActions,
    this.decoration,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    super.key,
  });
  final T value;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final String name;
  final String icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool keepValidVisibleWhileFocused;
  final bool keepErrorVisibleWhenUnfocused;
  final String Function(T)? deserialize;
  final T Function(String)? serialize;
  final String Function(T)? formatted;
  final String? Function(T)? validator;

  /// Called any time the text changes.
  final ValueChanged<T>? onChanged;

  /// Called when the user is done editing. Either by pressing done, or by losing focus.
  final ValueChanged<T>? onDone;

  /// Called when the users is done editing. It is responsible for what happens with focus.
  /// Prefer [onDone] or [onSubmitted] for handling the completion of editing.
  /// If left null, then the focus will go to the surrounding focus node when done editing.
  final VoidCallback? onEditingComplete;

  /// Called when the user presses done.
  final ValueChanged<T>? onSubmitted;

  /// Actions that can be performed when either the text field or the surrounding is focused.
  final List<ActionShortcut>? actions;

  /// Actions that can be performed when the text field is focused.
  final List<ActionShortcut>? textFieldActions;

  /// Actions that can be performed when the surrounding of the text field is focused.
  final List<ActionShortcut>? surroundingActions;

  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign textAlign;
  final bool readOnly;

  _State _parse(String value) {
    try {
      final object = serialize != null ? serialize?.call(value) : value as T;
      if (object == null) return _Invalid("Invalid $name: $value");
      final message = validator?.call(object);
      if (message != null) return _Invalid(message);
      return _Valid(object, "Valid $name: $value");
    } on FormatException catch (e) {
      final message = e.message.trim();
      return _Invalid(message.isNotEmpty ? message : "Invalid $name: $value");
    }
  }

  T? _updateState(String value, ValueNotifier<_State> state) {
    final parsed = _parse(value);
    state.value = parsed;
    if (parsed is _Valid) return parsed.value;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = focusNode ?? useFocusNode();
    final state = useState<_State>(_initial);

    final formattedValue = deserialize?.call(value) ?? value.toString();

    useFocusedChange(focus, ({required hasFocus}) {
      if (!hasFocus && !keepErrorVisibleWhenUnfocused) {
        state.value = _initial;
        return;
      }

      if (hasFocus && keepValidVisibleWhileFocused && state.value == _initial) {
        _updateState(formattedValue, state);
      }
    }, [formattedValue]);

    final baseDecoration = decoration ?? const InputDecoration();
    final effectiveDecoration = baseDecoration.copyWith(
      prefixIcon:
          baseDecoration.prefixIcon ??
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icones(
              icon,
              size: 18,
              color: state.value is _Invalid ? Colors.redAccent : null,
            ),
          ),
      hintText: baseDecoration.hintText ?? "Enter a $name",
      errorText:
          state.value.cast<_Invalid>()?.message ?? baseDecoration.errorText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedTextField(
          focusNode: focus,
          autofocus: autofocus,
          controller: controller,
          text: formattedValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: effectiveDecoration,
          style: style,
          maxLines: maxLines,
          textAlign: textAlign,
          readOnly: readOnly,
          actions: actions,
          textFieldActions: textFieldActions,
          surroundingActions: surroundingActions,
          onChanged: (value) {
            final object = _updateState(value, state);
            if (object != null) onChanged?.call(object);
          },
          onDone: keepErrorVisibleWhenUnfocused
              ? (value) {
                  final object = _updateState(value, state);
                  if (object != null) onDone?.call(object);
                }
              : null,
          onEditingComplete: onEditingComplete,
          onSubmitted: (value) {
            final object = _updateState(value, state);
            if (object != null) onSubmitted?.call(object);
          },
        ),
        _StateText(
          name: name,
          state: state.value,
          value: formatted?.call(value),
          keepValidVisible: keepValidVisibleWhileFocused,
        ),
      ],
    );
  }
}

class _StateText extends HookWidget {
  const _StateText({
    required this.name,
    required this.state,
    required this.value,
    this.keepValidVisible = false,
  });

  final String name;
  final _State state;
  final String? value;
  final bool keepValidVisible;

  @override
  Widget build(BuildContext context) {
    if (state is! _Valid) return Container();

    final child =
        Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                value ?? state.cast<_Valid>()?.message ?? "",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            )
            .animate()
            .moveY(begin: -4, duration: 300.ms, curve: Curves.easeInOut)
            .fadeIn(duration: 300.ms, curve: Curves.easeInOut)
            .then(delay: 300.ms)
            .shimmer(duration: 1.5.seconds, curve: Curves.easeInOut)
            .addEffects([
              if (!keepValidVisible) ...[
                ThenEffect(delay: 300.ms),
                MoveEffect(
                  end: const Offset(0, -4),
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
                FadeEffect(
                  begin: 1.0,
                  end: 0.0,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
                SwapEffect(builder: (_, _) => Container()),
              ],
            ]);

    if (!keepValidVisible) {
      return AnimatedSize(
        duration: 300.ms,
        curve: Curves.easeInOut,
        child: child,
      );
    }

    return child;
  }
}
