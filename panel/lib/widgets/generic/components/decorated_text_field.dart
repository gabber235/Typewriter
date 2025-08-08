import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart" hide useFocusNode;
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";

class DecoratedTextField extends HookWidget {
  const DecoratedTextField({
    required this.focusNode,
    this.controller,
    this.text,
    this.onChanged,
    this.onDone,
    this.onSubmitted,
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
  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final int? maxLines;
  final TextAlign textAlign;
  final bool readOnly;

  static final _ignoringKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.keyH,
    LogicalKeyboardKey.keyJ,
    LogicalKeyboardKey.keyK,
    LogicalKeyboardKey.keyL,
  };

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

    final focusType = useState(FocusType.none);

    return FocusHighlight(
      type: focusType.value,
      borderRadius: BorderRadius.circular(12),
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
            focusType.value = surroundingFocusNode.hasPrimaryFocus
                ? FocusType.focus
                : FocusType.none;
          },
          onKeyEvent: (node, event) {
            if (focusNode.hasPrimaryFocus &&
                _ignoringKeys.contains(event.logicalKey)) {
              return KeyEventResult.skipRemainingHandlers;
            }
            return KeyEventResult.ignored;
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
            textInputAction:
                maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
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
    );
  }
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

/// Because the official flutter_hooks package doesn't support the `descendantsAreTraversable` parameter
/// We have a pr waiting for it to be merged: https://github.com/rrousselGit/flutter_hooks/pull/476
/// This is a workaround until it is merged
FocusNode useFocusNode({
  String? debugLabel,
  FocusOnKeyEventCallback? onKeyEvent,
  bool skipTraversal = false,
  bool canRequestFocus = true,
  bool descendantsAreFocusable = true,
  bool descendantsAreTraversable = true,
}) {
  return use(
    _FocusNodeHook(
      debugLabel: debugLabel,
      onKeyEvent: onKeyEvent,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
    ),
  );
}

class _FocusNodeHook extends Hook<FocusNode> {
  const _FocusNodeHook({
    this.debugLabel,
    this.onKeyEvent,
    required this.skipTraversal,
    required this.canRequestFocus,
    required this.descendantsAreFocusable,
    required this.descendantsAreTraversable,
  });

  final String? debugLabel;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool skipTraversal;
  final bool canRequestFocus;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;

  @override
  _FocusNodeHookState createState() {
    return _FocusNodeHookState();
  }
}

class _FocusNodeHookState extends HookState<FocusNode, _FocusNodeHook> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: hook.debugLabel,
    onKeyEvent: hook.onKeyEvent,
    skipTraversal: hook.skipTraversal,
    canRequestFocus: hook.canRequestFocus,
    descendantsAreFocusable: hook.descendantsAreFocusable,
    descendantsAreTraversable: hook.descendantsAreTraversable,
  );

  @override
  void didUpdateHook(_FocusNodeHook oldHook) {
    _focusNode
      ..debugLabel = hook.debugLabel
      ..skipTraversal = hook.skipTraversal
      ..canRequestFocus = hook.canRequestFocus
      ..descendantsAreFocusable = hook.descendantsAreFocusable
      ..descendantsAreTraversable = hook.descendantsAreTraversable
      ..onKeyEvent = hook.onKeyEvent;
  }

  @override
  FocusNode build(BuildContext context) => _focusNode;

  @override
  void dispose() => _focusNode.dispose();

  @override
  String get debugLabel => 'useFocusNode';
}
