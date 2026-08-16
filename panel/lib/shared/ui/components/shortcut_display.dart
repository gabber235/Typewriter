import "dart:math" as math;

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:okcolor/models/extensions.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "shortcut_display.freezed.dart";

// The default spacing between the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 8;

// The minimum spacing between the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4;

@freezed
sealed class KeyStyle with _$KeyStyle {
  const factory KeyStyle.solid({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? shadowColor,
  }) = SolidKeyStyle;

  const factory KeyStyle.outline({Color? foregroundColor, Color? borderColor}) =
      OutlineKeyStyle;
}

class LogicalKeyBoardDisplay extends StatelessWidget {
  const LogicalKeyBoardDisplay({
    required this.keyBoardKey,
    this.style = const KeyStyle.solid(),
    this.size = 12,
    super.key,
  });

  final LogicalKeyboardKey keyBoardKey;
  final double size;
  final KeyStyle style;

  @override
  Widget build(BuildContext context) {
    return _KeyDisplay(size: size, style: style, child: _buildKey());
  }

  Widget _buildKey() {
    switch (keyBoardKey) {
      case LogicalKeyboardKey.control:
      case LogicalKeyboardKey.controlLeft:
      case LogicalKeyboardKey.controlRight:
        return const Icon(CupertinoIcons.control);
      case LogicalKeyboardKey.alt:
      case LogicalKeyboardKey.altLeft:
      case LogicalKeyboardKey.altRight:
        return const Icon(CupertinoIcons.alt);
      case LogicalKeyboardKey.meta:
      case LogicalKeyboardKey.metaLeft:
      case LogicalKeyboardKey.metaRight:
        return const Icon(CupertinoIcons.command);
      case LogicalKeyboardKey.shift:
      case LogicalKeyboardKey.shiftLeft:
      case LogicalKeyboardKey.shiftRight:
        return const Icon(CupertinoIcons.shift_fill);

      case LogicalKeyboardKey.backspace:
        return const Icon(Icons.backspace_rounded);
      case LogicalKeyboardKey.delete:
        return Text("Del");
      case LogicalKeyboardKey.enter:
        return const Icon(Icons.keyboard_return_rounded);
      case LogicalKeyboardKey.numpadEnter:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Num"),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_return_rounded),
          ],
        );
      case LogicalKeyboardKey.tab:
        return const Icon(Icons.keyboard_tab_rounded);
      case LogicalKeyboardKey.space:
        return const Icon(Icons.space_bar_rounded);
      case LogicalKeyboardKey.escape:
        return Text("Esc");
      case LogicalKeyboardKey.arrowUp:
        return const Icon(Icons.arrow_upward_rounded);
      case LogicalKeyboardKey.arrowDown:
        return const Icon(Icons.arrow_downward_rounded);
      case LogicalKeyboardKey.arrowLeft:
        return const Icon(Icons.arrow_back_rounded);
      case LogicalKeyboardKey.arrowRight:
        return const Icon(Icons.arrow_forward_rounded);
    }

    // If the trigger is a Unicode-character-producing key, then use the character
    if (keyBoardKey.keyId & LogicalKeyboardKey.planeMask == 0x0) {
      return Text(
        String.fromCharCode(
          keyBoardKey.keyId & LogicalKeyboardKey.valueMask,
        ).toUpperCase(),
      );
    }
    // Fallback to key label if no specific case is matched
    return Text(keyBoardKey.keyLabel);
  }
}

/// Cycles through a list of shortcuts, showing one at a time with animation.
class RotatingShortcuts extends HookWidget {
  const RotatingShortcuts({
    required this.shortcuts,
    this.size = 12.0,
    this.style = const KeyStyle.solid(),
    this.interval = const Duration(seconds: 5),
    super.key,
  });

  final List<ShortcutActivator> shortcuts;
  final double size;
  final KeyStyle style;
  final Duration interval;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }
    if (shortcuts.length == 1) {
      return ShortcutDisplay(
        shortcut: shortcuts.first,
        size: size,
        style: style,
      );
    }

    final index = useState(0);
    useTimer(interval, (_) {
      index.value = (index.value + 1) % shortcuts.length;
    });

    return ElasticSwitcher(
      child: KeyedSubtree(
        key: ValueKey<int>(index.value),
        child: ShortcutDisplay(
          shortcut: shortcuts[index.value % shortcuts.length],
          size: size,
          style: style,
        ),
      ),
    );
  }
}

/// Displays a single shortcut (label with optional icon) in a pill style.
class ShortcutDisplay extends StatelessWidget {
  const ShortcutDisplay({
    required this.shortcut,
    this.size = 12,
    this.style = const KeyStyle.solid(),
    super.key,
  });

  final ShortcutActivator shortcut;
  final KeyStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(
      _kLabelItemMinSpacing,
      _kLabelItemDefaultSpacing + density.horizontal * 2,
    );

    return Row(
      spacing: horizontalPadding,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final key in shortcut.keys)
          LogicalKeyBoardDisplay(keyBoardKey: key, size: size, style: style),
        switch (shortcut) {
          CharacterActivator(:final character) => _KeyDisplay(
            size: size,
            style: style,
            child: Text(character),
          ),
          _ => SizedBox(),
        },
      ],
    );
  }
}

class _KeyDisplay extends StatelessWidget {
  const _KeyDisplay({required this.child, required this.style, this.size = 12});
  final Widget child;
  final double size;
  final KeyStyle style;

  @override
  Widget build(BuildContext context) {
    final fixedWidth = switch (child) {
      Text(:final data) => (data?.length ?? 0) <= 1,
      _ => false,
    };
    final resolvedStyle = _resolveStyle(context);

    final height = size + 8;
    final width = fixedWidth ? size + 8 : null;

    final padding = const EdgeInsets.symmetric(horizontal: 4);
    final rounding = context.shapes.smallBorderRadius;

    final text = DefaultTextStyle(
      style: Theme.of(context).textTheme.labelMedium!.copyWith(
        color: resolvedStyle.foregroundColor,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
      child: IconTheme(
        data: IconThemeData(color: resolvedStyle.foregroundColor, size: size),
        child: Center(child: child),
      ),
    );

    switch (style) {
      case SolidKeyStyle():
        return AnimatedContainer(
          duration: 200.ms,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: rounding,
            color: resolvedStyle.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: resolvedStyle.shadowColor!,
                blurRadius: 0,
                offset: Offset(0, context.isDarkMode ? 3 : 2),
              ),
            ],
          ),
          height: height,
          width: width,
          child: Surface(color: resolvedStyle.backgroundColor!, child: text),
        );
      case OutlineKeyStyle():
        return AnimatedContainer(
          duration: 200.ms,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: rounding,
            border: Border.all(color: resolvedStyle.borderColor!),
          ),
          height: height,
          width: width,
          child: text,
        );
    }
  }

  _ResolvedKeyStyle _resolveStyle(BuildContext context) {
    final style = this.style;
    return switch (style) {
      SolidKeyStyle() => _resolveSolidStyle(context, style),
      OutlineKeyStyle() => _resolveOutlineStyle(context, style),
    };
  }

  _ResolvedKeyStyle _resolveSolidStyle(
    BuildContext context,
    SolidKeyStyle style,
  ) {
    final backgroundColor =
        style.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return _ResolvedKeyStyle(
      backgroundColor: backgroundColor,
      foregroundColor:
          style.foregroundColor ??
          _foregroundColorFor(context, backgroundColor),
      shadowColor:
          style.shadowColor ??
          backgroundColor.darker(context.isDarkMode ? 0.4 : 0.1),
    );
  }

  _ResolvedKeyStyle _resolveOutlineStyle(
    BuildContext context,
    OutlineKeyStyle style,
  ) {
    final foregroundColor =
        style.foregroundColor ??
        _foregroundColorFor(context, Surface.colorOf(context));
    return _ResolvedKeyStyle(
      foregroundColor: foregroundColor,
      borderColor: style.borderColor ?? foregroundColor.withValues(alpha: 0.3),
    );
  }

  Color _foregroundColorFor(BuildContext context, Color backgroundColor) {
    final theme = Theme.of(context);
    final backgroundBrightness = ThemeData.estimateBrightnessForColor(
      backgroundColor,
    );
    return backgroundBrightness == theme.brightness
        ? theme.colorScheme.onSurface
        : theme.colorScheme.surface;
  }
}

class _ResolvedKeyStyle {
  const _ResolvedKeyStyle({
    required this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
  });

  final Color foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
}
