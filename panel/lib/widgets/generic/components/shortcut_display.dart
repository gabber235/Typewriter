import "dart:math" as math;
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/timer.dart";

class _KeyDisplay extends StatelessWidget {
  const _KeyDisplay({required this.child});
  final Widget child;

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
      height: 20,
      width: fixedWidth ? 20 : null,
      child: DefaultTextStyle(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface,
            size: 12,
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
    super.key,
  });

  final LogicalKeyboardKey keyBoardKey;

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
      case LogicalKeyboardKey.tab:
        return const Icon(Icons.tab_rounded);
      case LogicalKeyboardKey.space:
        return const Icon(Icons.space_bar_rounded);
      case LogicalKeyboardKey.escape:
        return const Text("Esc");
      case LogicalKeyboardKey.arrowUp:
        return const Icon(Icons.arrow_upward_rounded);
      case LogicalKeyboardKey.arrowDown:
        return const Icon(Icons.arrow_downward_rounded);
      case LogicalKeyboardKey.arrowLeft:
        return const Icon(Icons.arrow_back_ios_rounded);
      case LogicalKeyboardKey.arrowRight:
        return const Icon(Icons.arrow_forward_ios_rounded);
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
    return _KeyDisplay(child: _buildKey());
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
    super.key,
  });

  final ShortcutActivator shortcut;

  @override
  Widget build(BuildContext context) {
    final density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(
      _kLabelItemMinSpacing,
      _kLabelItemDefaultSpacing + density.horizontal * 2,
    );
    final keys = switch (shortcut) {
      SingleActivator(
        :final alt,
        :final control,
        :final meta,
        :final shift,
        :final trigger
      ) =>
        [
          if (alt) LogicalKeyboardKey.alt,
          if (control) LogicalKeyboardKey.control,
          if (meta) LogicalKeyboardKey.meta,
          if (shift) LogicalKeyboardKey.shift,
          trigger,
        ],
      CharacterActivator(
        :final alt,
        :final control,
        :final meta,
      ) =>
        [
          if (alt) LogicalKeyboardKey.alt,
          if (control) LogicalKeyboardKey.control,
          if (meta) LogicalKeyboardKey.meta,
        ],
      LogicalKeySet(:final keys) => keys,
      _ => throw UnsupportedError(
          "Unsupported shortcut type ${shortcut.runtimeType}",
        ),
    };

    return Row(
      spacing: horizontalPadding,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final key in keys) LogicalKeyBoardDisplay(keyBoardKey: key),
        switch (shortcut) {
          CharacterActivator(:final character) =>
            _KeyDisplay(child: Text(character)),
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
    this.interval = const Duration(seconds: 4),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.style,
    super.key,
  });

  final List<ShortcutActivator> shortcuts;
  final Duration interval;
  final Duration transitionDuration;
  final Curve curve;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }
    if (shortcuts.length == 1) {
      return ShortcutDisplay(
        shortcut: shortcuts.first,
      );
    }

    final index = useState(0);
    useTimer(interval, (_) {
      index.value = (index.value + 1) % shortcuts.length;
    });

    return AnimatedSwitcher(
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
          shortcut: shortcuts[index.value],
        ),
      ),
    );
  }
}

/// A helper class used to generate shortcut labels for a
/// [MenuSerializableShortcut] (a subset of the subclasses of
/// [ShortcutActivator]).
///
/// This helper class is typically used by the [MenuItemButton] and
/// [SubmenuButton] classes to display a label for their assigned shortcuts.
///
/// Call [getShortcutLabel] with the [MenuSerializableShortcut] to get a label
/// for it.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
class LocalizedShortcutLabeler {
  LocalizedShortcutLabeler._();

  static LocalizedShortcutLabeler? _instance;

  static final Map<LogicalKeyboardKey, String> _shortcutGraphicEquivalents =
      <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.arrowLeft: "←",
    LogicalKeyboardKey.arrowRight: "→",
    LogicalKeyboardKey.arrowUp: "↑",
    LogicalKeyboardKey.arrowDown: "↓",
    LogicalKeyboardKey.enter: "↵",
  };

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.shiftRight,
  };

  /// Return the instance for this singleton.
  // ignore: prefer_constructors_over_static_methods
  static LocalizedShortcutLabeler get instance {
    return _instance ??= LocalizedShortcutLabeler._();
  }

  // Caches the created shortcut key maps so that creating one of these isn't
  // expensive after the first time for each unique localizations object.
  final Map<MaterialLocalizations, Map<LogicalKeyboardKey, String>>
      _cachedShortcutKeys =
      <MaterialLocalizations, Map<LogicalKeyboardKey, String>>{};

  /// Returns the label to be shown to the user in the UI when a
  /// [MenuSerializableShortcut] is used as a keyboard shortcut.
  ///
  /// When [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], this will return graphical key representations when
  /// it can. For instance, the default [LogicalKeyboardKey.shift] will return
  /// '⇧', and the arrow keys will return arrows. The key
  /// [LogicalKeyboardKey.meta] will show as '⌘', [LogicalKeyboardKey.control]
  /// will show as '˄', and [LogicalKeyboardKey.alt] will show as '⌥'.
  ///
  /// The keys are joined by spaces on macOS and iOS, and by "+" on other
  /// platforms.
  String getShortcutLabel(
    MenuSerializableShortcut shortcut,
    MaterialLocalizations localizations,
  ) {
    final serialized = shortcut.serializeForMenu();
    final String keySeparator;
    if (_usesSymbolicModifiers) {
      // Use "⌃ ⇧ A" style on macOS and iOS.
      keySeparator = " ";
    } else {
      // Use "Ctrl+Shift+A" style.
      keySeparator = "+";
    }
    if (serialized.trigger != null) {
      final trigger = serialized.trigger!;
      final modifiers = <String>[
        if (_usesSymbolicModifiers) ...<String>[
          // macOS/iOS platform convention uses this ordering, with ⌘ always last.
          if (serialized.control!)
            _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.alt!)
            _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.shift!)
            _getModifierLabel(LogicalKeyboardKey.shift, localizations),
          if (serialized.meta!)
            _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ] else ...<String>[
          // This order matches the LogicalKeySet version.
          if (serialized.alt!)
            _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.control!)
            _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.meta!)
            _getModifierLabel(LogicalKeyboardKey.meta, localizations),
          if (serialized.shift!)
            _getModifierLabel(LogicalKeyboardKey.shift, localizations),
        ],
      ];
      String? shortcutTrigger;
      final logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger];
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
        if (shortcutTrigger == null &&
            logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
          // If the trigger is a Unicode-character-producing key, then use the
          // character.
          shortcutTrigger = String.fromCharCode(
            logicalKeyId & LogicalKeyboardKey.valueMask,
          ).toUpperCase();
        }
        // Fall back to the key label if all else fails.
        shortcutTrigger ??= trigger.keyLabel;
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger != null && shortcutTrigger.isNotEmpty)
          shortcutTrigger,
      ].join(keySeparator);
    } else if (serialized.character != null) {
      final modifiers = <String>[
        // Character based shortcuts cannot check shifted keys.
        if (_usesSymbolicModifiers) ...<String>[
          // macOS/iOS platform convention uses this ordering, with ⌘ always last.
          if (serialized.control!)
            _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.alt!)
            _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.meta!)
            _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ] else ...<String>[
          // This order matches the LogicalKeySet version.
          if (serialized.alt!)
            _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.control!)
            _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.meta!)
            _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ],
      ];
      return <String>[...modifiers, serialized.character!].join(keySeparator);
    }
    throw UnimplementedError(
      "Shortcut labels for ShortcutActivators that do not implement "
      "MenuSerializableShortcut (e.g. ShortcutActivators other than SingleActivator or "
      "CharacterActivator) are not supported.",
    );
  }

  // Tries to look up the key in an internal table, and if it can't find it,
  // then fall back to the key's keyLabel.
  String? _getLocalizedName(
    LogicalKeyboardKey key,
    MaterialLocalizations localizations,
  ) {
    // Since this is an expensive table to build, we cache it based on the
    // localization object. There's currently no way to clear the cache, but
    // it's unlikely that more than one or two will be cached for each run, and
    // they're not huge.
    _cachedShortcutKeys[localizations] ??= <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.altGraph: localizations.keyboardKeyAltGraph,
      LogicalKeyboardKey.backspace: localizations.keyboardKeyBackspace,
      LogicalKeyboardKey.capsLock: localizations.keyboardKeyCapsLock,
      LogicalKeyboardKey.channelDown: localizations.keyboardKeyChannelDown,
      LogicalKeyboardKey.channelUp: localizations.keyboardKeyChannelUp,
      LogicalKeyboardKey.delete: localizations.keyboardKeyDelete,
      LogicalKeyboardKey.eject: localizations.keyboardKeyEject,
      LogicalKeyboardKey.end: localizations.keyboardKeyEnd,
      LogicalKeyboardKey.escape: localizations.keyboardKeyEscape,
      LogicalKeyboardKey.fn: localizations.keyboardKeyFn,
      LogicalKeyboardKey.home: localizations.keyboardKeyHome,
      LogicalKeyboardKey.insert: localizations.keyboardKeyInsert,
      LogicalKeyboardKey.numLock: localizations.keyboardKeyNumLock,
      LogicalKeyboardKey.numpad1: localizations.keyboardKeyNumpad1,
      LogicalKeyboardKey.numpad2: localizations.keyboardKeyNumpad2,
      LogicalKeyboardKey.numpad3: localizations.keyboardKeyNumpad3,
      LogicalKeyboardKey.numpad4: localizations.keyboardKeyNumpad4,
      LogicalKeyboardKey.numpad5: localizations.keyboardKeyNumpad5,
      LogicalKeyboardKey.numpad6: localizations.keyboardKeyNumpad6,
      LogicalKeyboardKey.numpad7: localizations.keyboardKeyNumpad7,
      LogicalKeyboardKey.numpad8: localizations.keyboardKeyNumpad8,
      LogicalKeyboardKey.numpad9: localizations.keyboardKeyNumpad9,
      LogicalKeyboardKey.numpad0: localizations.keyboardKeyNumpad0,
      LogicalKeyboardKey.numpadAdd: localizations.keyboardKeyNumpadAdd,
      LogicalKeyboardKey.numpadComma: localizations.keyboardKeyNumpadComma,
      LogicalKeyboardKey.numpadDecimal: localizations.keyboardKeyNumpadDecimal,
      LogicalKeyboardKey.numpadDivide: localizations.keyboardKeyNumpadDivide,
      LogicalKeyboardKey.numpadEnter: localizations.keyboardKeyNumpadEnter,
      LogicalKeyboardKey.numpadEqual: localizations.keyboardKeyNumpadEqual,
      LogicalKeyboardKey.numpadMultiply:
          localizations.keyboardKeyNumpadMultiply,
      LogicalKeyboardKey.numpadParenLeft:
          localizations.keyboardKeyNumpadParenLeft,
      LogicalKeyboardKey.numpadParenRight:
          localizations.keyboardKeyNumpadParenRight,
      LogicalKeyboardKey.numpadSubtract:
          localizations.keyboardKeyNumpadSubtract,
      LogicalKeyboardKey.pageDown: localizations.keyboardKeyPageDown,
      LogicalKeyboardKey.pageUp: localizations.keyboardKeyPageUp,
      LogicalKeyboardKey.power: localizations.keyboardKeyPower,
      LogicalKeyboardKey.powerOff: localizations.keyboardKeyPowerOff,
      LogicalKeyboardKey.printScreen: localizations.keyboardKeyPrintScreen,
      LogicalKeyboardKey.scrollLock: localizations.keyboardKeyScrollLock,
      LogicalKeyboardKey.select: localizations.keyboardKeySelect,
      LogicalKeyboardKey.space: localizations.keyboardKeySpace,
    };
    return _cachedShortcutKeys[localizations]![key];
  }

  String _getModifierLabel(
    LogicalKeyboardKey modifier,
    MaterialLocalizations localizations,
  ) {
    assert(
      _modifiers.contains(modifier),
      "${modifier.keyLabel} is not a modifier key",
    );
    if (modifier == LogicalKeyboardKey.meta ||
        modifier == LogicalKeyboardKey.metaLeft ||
        modifier == LogicalKeyboardKey.metaRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          return localizations.keyboardKeyMeta;
        case TargetPlatform.windows:
          return localizations.keyboardKeyMetaWindows;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return "⌘";
      }
    }
    if (modifier == LogicalKeyboardKey.alt ||
        modifier == LogicalKeyboardKey.altLeft ||
        modifier == LogicalKeyboardKey.altRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyAlt;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return "⌥";
      }
    }
    if (modifier == LogicalKeyboardKey.control ||
        modifier == LogicalKeyboardKey.controlLeft ||
        modifier == LogicalKeyboardKey.controlRight) {
      // '⎈' (a boat helm wheel, not an asterisk) is apparently the standard
      // icon for "control", but only seems to appear on the French Canadian
      // keyboard. A '✲' (an open center asterisk) appears on some Microsoft
      // keyboards. For all but macOS (which has standardized on "⌃", it seems),
      // we just return the local translation of "Ctrl".
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyControl;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return "⌃";
      }
    }
    if (modifier == LogicalKeyboardKey.shift ||
        modifier == LogicalKeyboardKey.shiftLeft ||
        modifier == LogicalKeyboardKey.shiftRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyShift;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return "⇧";
      }
    }
    throw ArgumentError("Keyboard key ${modifier.keyLabel} is not a modifier.");
  }

  /// Whether [defaultTargetPlatform] is an Apple platform (Mac or iOS).
  bool get _isCupertino {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  /// Whether [defaultTargetPlatform] is one that uses symbolic shortcuts.
  ///
  /// Mac and iOS use special symbols for modifier keys instead of their names,
  /// render them in a particular order defined by Apple's human interface
  /// guidelines, and format them so that the modifier keys always align.
  bool get _usesSymbolicModifiers {
    return _isCupertino;
  }
}
