import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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

/// Edits a value through a text representation while retaining the last
/// valid value during invalid drafts.
///
/// [deserialize] and [serialize] define the representation boundary. Invalid
/// input is shown locally and is not sent to [onChanged]. Set [mixed] when
/// there is no single starting value; the first valid edit then replaces the
/// selected values.
class ValidatedTextField<T> extends HookConsumerWidget {
  const ValidatedTextField({
    required this.value,
    this.controller,
    this.focusNode,
    this.inputFieldController,
    this.autofocus = EditorTextFieldAutoFocus.none,
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
    this.onInputFocus,
    this.onInputBlur,
    this.onDismiss,
    this.actions,
    this.textFieldActions,
    this.surroundingActions,
    this.decoration,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.selectAllOnFocus = false,
    this.mixed = false,
    super.key,
  }) : assert((value == null) == mixed);
  final T? value;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputFieldController? inputFieldController;
  final EditorTextFieldAutoFocus autofocus;
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

  /// Called when the user is done editing, either by pressing done or losing
  /// focus.
  final ValueChanged<T>? onDone;

  /// Called when editing completes to control the next focus transition.
  /// Prefer [onDone] or [onSubmitted] when only the value needs handling. If
  /// null, focus moves to the surrounding focus node.
  final VoidCallback? onEditingComplete;

  /// Called when the user presses done.
  final ValueChanged<T>? onSubmitted;
  final VoidCallback? onInputFocus;
  final VoidCallback? onInputBlur;
  final VoidCallback? onDismiss;

  /// Actions available while either focus boundary is active.
  final List<ActionShortcut>? actions;

  /// Actions available while the text field has focus.
  final List<ActionShortcut>? textFieldActions;

  /// Actions available while the surrounding focus boundary has focus.
  final List<ActionShortcut>? surroundingActions;

  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign textAlign;
  final bool readOnly;
  final bool selectAllOnFocus;
  final bool mixed;

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
    final fallbackFocus = useFocusNode();
    final focus =
        inputFieldController?.inputFocusNode ?? focusNode ?? fallbackFocus;
    final state = useState<_State>(_initial);

    final current = value;
    final formattedValue = current == null
        ? null
        : deserialize?.call(current) ?? current.toString();

    useFocusedChange(focus, ({required hasFocus}) {
      if (!hasFocus && !keepErrorVisibleWhenUnfocused) {
        state.value = _initial;
        return;
      }

      if (hasFocus &&
          formattedValue != null &&
          keepValidVisibleWhileFocused &&
          state.value == _initial) {
        _updateState(formattedValue, state);
      }
    }, [formattedValue]);

    final suppliedDecoration = decoration ?? const InputDecoration();
    final baseDecoration = mixed
        ? suppliedDecoration.forMixedValue
        : suppliedDecoration;
    final effectiveDecoration = baseDecoration.copyWith(
      prefixIcon:
          baseDecoration.prefixIcon ??
          Padding(
            padding: EdgeInsets.all(context.spacing.space2),
            child: Icones(
              icon,
              size: 18,
              color: state.value is _Invalid ? context.colors.danger : null,
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
        EditorTextField(
          focusNode: focus,
          inputFieldController: inputFieldController,
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
          selectAllOnFocus: selectAllOnFocus,
          actions: actions,
          textFieldActions: textFieldActions,
          surroundingActions: surroundingActions,
          onChanged: (value) {
            final object = _updateState(value, state);
            if (object != null) onChanged?.call(object);
          },
          onDone: (value) {
            if (keepErrorVisibleWhenUnfocused) {
              final object = _updateState(value, state);
              if (object != null) onDone?.call(object);
            }
            onInputBlur?.call();
          },
          onEditingComplete: onEditingComplete,
          onSubmitted: (value) {
            final object = _updateState(value, state);
            if (object != null) onSubmitted?.call(object);
          },
          onInputFocus: onInputFocus,
          onDismiss: onDismiss,
        ),
        _StateText(
          name: name,
          state: state.value,
          value: current == null ? null : formatted?.call(current),
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
              padding: EdgeInsets.only(
                left: context.spacing.space2,
                top: context.spacing.space1,
              ),
              child: Text(
                value ?? state.cast<_Valid>()?.message ?? "",
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.colors.success),
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
