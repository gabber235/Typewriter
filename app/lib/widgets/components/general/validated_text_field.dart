import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/widgets/components/general/decorated_text_field.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";

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
    this.name = "",
    this.icon = TWIcons.textFields,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.keepValidVisibleWhileFocused = false,
    this.deserialize,
    this.serialize,
    this.formatted,
    this.validator,
    this.onChanged,
    this.onDone,
    this.onSubmitted,
    super.key,
  });
  final T value;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String name;
  final String icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool keepValidVisibleWhileFocused;
  final String Function(T)? deserialize;
  final T Function(String)? serialize;
  final String Function(T)? formatted;
  final String? Function(T)? validator;
  final void Function(T)? onChanged;
  final void Function(T)? onDone;
  final void Function(T)? onSubmitted;

  _State _parse(String value) {
    try {
      final object = serialize != null ? serialize?.call(value) : value as T;
      if (object == null) return _Invalid("Invalid $name: $value");
      final message = validator?.call(object);
      if (message != null) return _Invalid(message);
      return _Valid(object, "Valid $name: $value");
    } on FormatException catch (_) {
      return _Invalid("Invalid $name: $value");
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
      if (!hasFocus) state.value = _initial;

      if (hasFocus && keepValidVisibleWhileFocused && state.value == _initial) {
        _updateState(formattedValue, state);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedTextField(
          focus: focus,
          controller: controller,
          text: formattedValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Iconify(
                icon,
                size: 18,
                color: state.value is _Invalid ? Colors.redAccent : null,
              ),
            ),
            hintText: "Enter a $name",
            errorText: state.value.cast<_Invalid>()?.message,
          ),
          onChanged: (value) {
            final object = _updateState(value, state);
            if (object != null) onChanged?.call(object);
          },
          onDone: (value) {
            final object = _updateState(value, state);
            if (object != null) onDone?.call(object);
          },
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

    final child = Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Text(
        value ?? state.cast<_Valid>()?.message ?? "",
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.green),
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
        SwapEffect(builder: (_, __) => Container()),
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
