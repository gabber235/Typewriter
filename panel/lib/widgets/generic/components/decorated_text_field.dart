import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";

class DecoratedTextField extends HookWidget {
  const DecoratedTextField({
    required this.focusNode,
    this.controller,
    this.text,
    this.onChanged,
    this.onDone,
    this.onSubmitted,
    this.actions,
    this.textFieldActions,
    this.surroundingActions,
    this.style,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.decoration,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    super.key,
  }) : super();
  final TextEditingController? controller;
  final FocusNode focusNode;
  final String? text;

  /// Called any time the text changes.
  final Function(String)? onChanged;

  /// Called when the user is done editing. Either by pressing done, or by losing focus.
  final Function(String)? onDone;

  /// Called when the user presses done.
  final Function(String)? onSubmitted;

  /// Actions that can be performed when either the text field or the surrounding is focused.
  final List<ActionShortcut>? actions;

  /// Actions that can be performed when the text field is focused.
  final List<ActionShortcut>? textFieldActions;

  /// Actions that can be performed when the surrounding of the text field is focused.
  final List<ActionShortcut>? surroundingActions;

  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final int? maxLines;
  final TextAlign textAlign;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? useTextEditingController(text: text);

    // When we are not focused, we want to update the controller with the latest.
    // Since other people may update the text and we want that reflected.
    // However, when we are focused, we don't want to update the controller as this causes the cursor to jump.
    useEffect(
      () {
        if (!focusNode.hasFocus && text != null) {
          controller.text = text ?? "";
        }
        return null;
      },
      [text],
    );

    useFocusedChange(
      focusNode,
      ({required hasFocus}) {
        if (hasFocus) {
          if (text != null) {
            controller.text = text!;
          }
        } else {
          onDone?.call(controller.text);
        }
      },
      [text],
    );

    final surroundingFocusNode = useFocusNode(
      debugLabel: "Surrounding focus node",
      descendantsAreTraversable: false,
    );

    useListenable(surroundingFocusNode);

    final focusType = useState(FocusType.none);

    return FocusHighlight(
      type: focusType.value,
      borderRadius: BorderRadius.circular(12),
      child: ManagedActionSet(
        shortcuts: [
          if (surroundingFocusNode.hasPrimaryFocus) ...[
            ActionShortcut(
              id: "focus_input",
              label: "Focus Input",
              description: "Focus the input field",
              activators: [
                SingleActivator(LogicalKeyboardKey.enter),
                SingleActivator(LogicalKeyboardKey.space),
              ],
              priority: 100,
            ),
            ...?surroundingActions,
          ],
          if (focusNode.hasPrimaryFocus) ...[
            ActionShortcut(
              id: "dismiss_input",
              label: "Dismiss Input",
              description: "Dismiss the input field",
              activators: [
                SingleActivator(LogicalKeyboardKey.escape),
              ],
              priority: 100,
            ),
            ...?textFieldActions,
          ],
          if (surroundingFocusNode.hasFocus) ...?actions,
        ],
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction(
              onInvoke: (intent) {
                if (surroundingFocusNode.hasPrimaryFocus) {
                  focusNode.requestFocus();
                }
                return null;
              },
            ),
            DismissIntent: DismissActionCallback(
              onInvoke: (intent) {
                if (focusNode.hasPrimaryFocus) {
                  surroundingFocusNode.requestFocus();
                }
              },
            ),
          },
          child: Focus(
            focusNode: surroundingFocusNode,
            onFocusChange: (_) {
              focusType.value =
                  FocusHighlighting.onlyPrimary(surroundingFocusNode);
            },
            onKeyEvent: (node, event) {
              if (!focusNode.hasPrimaryFocus) return KeyEventResult.ignored;
              final shouldBlock =
                  _shouldBlockKeyEventForTextField(context, event);
              return shouldBlock
                  ? KeyEventResult.skipRemainingHandlers
                  : KeyEventResult.ignored;
            },
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              onEditingComplete: () {
                onDone?.call(controller.text);
                onChanged?.call(controller.text);
                onSubmitted?.call(controller.text);
              },
              onSubmitted: (value) {
                onDone?.call(value);
                onChanged?.call(value);
                onSubmitted?.call(value);
              },
              onChanged: onChanged,
              style: style,
              textCapitalization: TextCapitalization.none,
              textInputAction: maxLines == 1
                  ? TextInputAction.done
                  : TextInputAction.newline,
              textAlign: textAlign,
              maxLines: maxLines,
              keyboardType: keyboardType,
              readOnly: readOnly,
              selectAllOnFocus: false,
              inputFormatters: [
                if (inputFormatters != null) ...inputFormatters!,
              ],
              decoration: decoration,
            ),
          ),
        ),
      ),
    );
  }
}

bool _shouldBlockKeyEventForTextField(BuildContext context, KeyEvent event) {
  if (event.logicalKey == LogicalKeyboardKey.escape) {
    return false;
  }

  final hardware = HardwareKeyboard.instance;
  final isControlDown =
      hardware.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
          hardware.isLogicalKeyPressed(LogicalKeyboardKey.controlRight);
  final isMetaDown =
      hardware.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
          hardware.isLogicalKeyPressed(LogicalKeyboardKey.metaRight);
  final isAltDown = hardware.isLogicalKeyPressed(LogicalKeyboardKey.altLeft) ||
      hardware.isLogicalKeyPressed(LogicalKeyboardKey.altRight);

  return !isControlDown && !isMetaDown && !isAltDown;
}

class DismissActionCallback extends DismissAction {
  DismissActionCallback({required this.onInvoke});

  final ValueChanged<DismissIntent>? onInvoke;
  @override
  Object? invoke(DismissIntent intent) {
    onInvoke?.call(intent);
    return null;
  }
}
