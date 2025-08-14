import "dart:math" as math;
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/timer.dart";
import "package:typewriter_panel/utils/shortuct.dart";

class _KeyDisplay extends StatelessWidget {
  const _KeyDisplay({
    required this.child,
    this.size = 12,
  });
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fixedWidth = switch (child) {
      Text(:final data) => (data?.length ?? 0) <= 1,
      _ => false,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      height: size + 8,
      width: fixedWidth ? size + 8 : null,
      child: DefaultTextStyle(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface,
            size: size,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class LogicalKeyBoardDisplay extends HookWidget {
  const LogicalKeyBoardDisplay({
    required this.keyBoardKey,
    this.size = 12,
    super.key,
  });

  final LogicalKeyboardKey keyBoardKey;
  final double size;

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
        return const Text("Del");
      case LogicalKeyboardKey.enter:
        return const Icon(Icons.keyboard_return_rounded);
      case LogicalKeyboardKey.numpadEnter:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Num"),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_return_rounded),
          ],
        );
      case LogicalKeyboardKey.tab:
        return const Icon(Icons.keyboard_tab_rounded);
      case LogicalKeyboardKey.space:
        return const Icon(Icons.space_bar_rounded);
      case LogicalKeyboardKey.escape:
        return const Text("Esc");
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
        String.fromCharCode(keyBoardKey.keyId & LogicalKeyboardKey.valueMask)
            .toUpperCase(),
      );
    }
    // Fallback to key label if no specific case is matched
    return Text(keyBoardKey.keyLabel);
  }

  @override
  Widget build(BuildContext context) {
    return _KeyDisplay(
      size: size,
      child: _buildKey(),
    );
  }
}

// The default spacing between the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 8;

// The minimum spacing between the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4;

/// Displays a single shortcut (label with optional icon) in a pill style.
class ShortcutDisplay extends StatelessWidget {
  const ShortcutDisplay({
    required this.shortcut,
    this.size = 12,
    super.key,
  });

  final ShortcutActivator shortcut;
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
          LogicalKeyBoardDisplay(keyBoardKey: key, size: size),
        switch (shortcut) {
          CharacterActivator(:final character) =>
            _KeyDisplay(size: size, child: Text(character)),
          _ => SizedBox(),
        },
      ],
    );
  }
}

/// Cycles through a list of shortcuts, showing one at a time with animation.
class RotatingShortcuts extends HookWidget {
  const RotatingShortcuts({
    required this.shortcuts,
    this.size = 12.0,
    this.interval = const Duration(seconds: 5),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    super.key,
  });

  final List<ShortcutActivator> shortcuts;
  final double size;
  final Duration interval;
  final Duration transitionDuration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }
    if (shortcuts.length == 1) {
      return ShortcutDisplay(
        shortcut: shortcuts.first,
        size: size,
      );
    }

    final index = useState(0);
    useTimer(interval, (_) {
      index.value = (index.value + 1) % shortcuts.length;
    });

    return AnimatedSize(
      duration: 1000.ms,
      curve: ElasticOutCurve(0.9),
      child: AnimatedSwitcher(
        duration: transitionDuration,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(parent: animation, curve: curve);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: curved, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(index.value),
          child: ShortcutDisplay(
            shortcut: shortcuts[index.value % shortcuts.length],
            size: size,
          ),
        ),
      ),
    );
  }
}
