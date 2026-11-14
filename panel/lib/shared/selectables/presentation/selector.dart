import "package:typewriter_panel/typewriter_panel.dart";

/// Associates a widget subtree with its selectable identifier.
///
/// The scope is a focus lookup boundary, not selection state. It lets graph
/// navigation and other consumers map Flutter's primary focus back to an item
/// without making focus imply that the item is selected.
class SelectableScope extends HookWidget {
  const SelectableScope({required this.id, required this.child, super.key});

  final SelectableIdentifier id;
  final Widget child;

  /// Returns the identifier under Flutter's primary focus, if any.
  ///
  /// Identity belongs to the focus tree, so this remains safe during widget
  /// removal and layout. It returns null outside a [SelectableScope].
  static SelectableIdentifier? primaryFocusedId() {
    for (
      var node = FocusManager.instance.primaryFocus;
      node != null;
      node = node.parent
    ) {
      if (node is _SelectableFocusNode) return node.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final node = useMemoized(() => _SelectableFocusNode(id))..id = id;
    useEffect(() => node.dispose, [node]);
    return Focus(
      focusNode: node,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: child,
    );
  }
}

final class _SelectableFocusNode extends FocusNode {
  _SelectableFocusNode(this.id)
    : super(canRequestFocus: false, skipTraversal: true);

  SelectableIdentifier id;
}

/// Combines selection gestures, focus handling, context actions, and item UI.
///
/// [selectableId] participates in provider selection. [focusNode] tracks
/// keyboard focus independently, and [builder] receives both states so callers
/// can render their distinction. Activation dispatches the shared selector
/// intent before updating the canonical selection.
///
/// Every selectable follows one model. A plain click or Enter selects only
/// this item. Command+click on Apple platforms, Control+click elsewhere, or
/// Space adds or removes it. Shift+click selects the range from the anchor to
/// it, and Shift with an arrow moves focus and extends that range, both in
/// the visible order of the nearest [SelectionSurface], where the selector
/// registers itself. Control+click on Apple platforms opens the context menu.
/// In select mode, on a surface holding a selected item, the item reads as
/// checked or not, and a [SelectorCheck] in [builder] shows its check.
class Selector extends HookConsumerWidget {
  const Selector({
    required this.selectableId,
    required this.builder,
    required this.focusNode,
    this.onFocusChange,
    this.onDoubleTap,
    this.shortcuts = const {},
    super.key,
  });

  /// Identifier changed by taps and keyboard activation.
  final SelectableIdentifier selectableId;

  // ignore: avoid_positional_boolean_parameters
  final Widget Function(bool isSelected, bool isFocused, bool isHovered)
  builder;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// A function that will be called when the focus changes.
  ///
  /// Called with true if the [focusNode] has primary focus.
  final ValueChanged<bool>? onFocusChange;

  /// Optional callback for a double tap without changing selection semantics.
  final VoidCallback? onDoubleTap;

  /// Item specific intents that take precedence over closed menu traversal.
  /// Descendant controls and an open menu retain their closer shortcut scopes.
  final Map<ShortcutActivator, Intent> shortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(isSelectedProvider(selectableId));
    final isFocused = useState(false);
    final isHovered = useState(false);
    final controller = useMemoized(AnchoredPopupController.new);
    useEffect(() => controller.dispose, [controller]);
    final anchorKey = useGlobalKey();
    final pendingContextPosition = useState<Offset?>(null);
    final contextTargets = useState<List<SelectableIdentifier>?>(null);
    final selection = ref.watch(selectionProvider);
    final selected = ref.watch(selectedProvider);
    final surface = SelectionSurface.maybeOf(context);
    // Select mode shows checks only on a surface holding a selected item,
    // so the rest of the page stays as it was.
    final selecting =
        ref.watch(selectModeProvider) &&
        (surface == null ? isSelected : selection.any(surface.contains));
    useEffect(() => surface?.register(context, selectableId), [
      surface,
      selectableId,
    ]);

    final source = SelectionOperationsRoot.of(context);
    final captured = contextTargets.value;
    final operations =
        (captured == null
            ? null
            : source.operationsForTargets(ref, captured)) ??
        source.operationsFor(ref, selected.value ?? const []);

    useFocusedChange(focusNode, ({required hasFocus}) {
      isFocused.value = hasFocus;
      if (!hasFocus) pendingContextPosition.value = null;
      onFocusChange?.call(hasFocus);
      return null;
    }, [focusNode, onFocusChange]);

    void activateContext(Offset globalPosition) {
      if (!ref.read(selectionProvider).contains(selectableId)) {
        ref.read(selectionProvider.notifier).selectOnly(selectableId);
      }
      contextTargets.value = List.of(ref.read(selectionProvider));
      focusNode.requestFocus();
      pendingContextPosition.value = globalPosition;
    }

    // Announces the choice to the surface, then changes the selection.
    void choose(
      void Function(Selection selection) change, {
      required bool throughTap,
    }) {
      Actions.maybeInvoke(
        context,
        SelectedSelectorIntent(
          selectableId: selectableId,
          focusNode: focusNode,
          throughTap: throughTap,
          throughActivateIntent: !throughTap,
        ),
      );
      change(ref.read(selectionProvider.notifier));
    }

    List<SelectableIdentifier> order() => surface?.order ?? [selectableId];

    // The modifiers held now: Shift selects a range, Command or Control
    // toggles, and Control on Apple platforms asks for the context menu.
    ({bool range, bool toggle, bool menu}) modifiers() {
      final keyboard = HardwareKeyboard.instance;
      return (
        range: keyboard.isShiftPressed,
        toggle: hasOverrideDown,
        menu: isApple && keyboard.isControlPressed,
      );
    }

    // The modifiers held when the pointer went down. A tap resolves only
    // once a double tap is ruled out, and the user has often let go of the
    // modifier by then.
    final pressed = useRef<({bool range, bool toggle, bool menu})?>(null);

    void tap(TapUpDetails details) {
      final held = pressed.value ?? modifiers();
      pressed.value = null;
      if (controller.isOpen) return controller.close();
      if (held.menu) return activateContext(details.globalPosition);
      choose(throughTap: true, (selection) {
        if (held.range) {
          selection.selectRange(selectableId, order: order());
        } else if (held.toggle) {
          selection.toggle(selectableId);
        } else {
          selection.selectOnly(selectableId);
        }
      });
      focusNode.requestFocus();
    }

    void extend(TraversalDirection direction) {
      final at = focusNode.context;
      if (at == null) return;
      // The move is the one a plain arrow makes here; the range follows
      // once focus has landed, which a request applies in a microtask.
      Actions.maybeInvoke(at, DirectionalFocusIntent(direction));
      Future.microtask(() {
        if (!context.mounted) return;
        final to = SelectableScope.primaryFocusedId() ?? selectableId;
        final items = SelectionSurface.ofPrimaryFocus()?.order ?? order();
        ref
            .read(selectionProvider.notifier)
            .selectRange(to, order: items, from: selectableId);
      });
    }

    useEffect(() {
      final position = pendingContextPosition.value;
      if (position == null) return null;
      var active = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!active || !context.mounted) return;
        if (!ref.read(selectionProvider).contains(selectableId) ||
            !focusNode.hasFocus) {
          pendingContextPosition.value = null;
          return;
        }
        if (selected.isLoading) return;
        pendingContextPosition.value = null;
        if (selected.hasError || operations.isEmpty) return;
        final anchor = anchorKey.currentContext?.findRenderObject();
        if (anchor is! RenderBox || !anchor.attached) return;
        controller.openAt(anchor.globalToLocal(position));
      });
      return () => active = false;
    }, [pendingContextPosition.value, selection, selected, source]);

    // Gaining focus presses the item in and lets it come back, with press.
    final press = resolveMotion(context, MotionToken.press);
    final focusPulse = useMotionController();
    useEffect(() {
      if (!isFocused.value || !focusPulse.settled) return null;
      focusPulse.to(1, press).whenCompleteOrCancel(() {
        if (context.mounted) focusPulse.to(0, press);
      });
      return null;
    }, [isFocused.value]);

    // The item is one control for assistive technology: its selection,
    // focus and tap merge with the text it shows, so a screen reader names
    // and activates it by what a sighted user reads, however deep the item
    // nests that text. Activating it selects, as a tap does.
    return KeyedSubtree(
      key: Key(selectableId.id),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          selected: isSelected,
          checked: selecting ? isSelected : null,
          child: ContextMenuRegion(
            key: anchorKey,
            onClose: () => contextTargets.value = null,
            items: selectionOperationMenuItems(operations, ref),
            enableGestures: false,
            controller: controller,
            child: Listener(
              onPointerDown: (_) => pressed.value = modifiers(),
              child: GestureDetector(
                onSecondaryTapUp: (details) =>
                    activateContext(details.globalPosition),
                onLongPressStart: (details) =>
                    activateContext(details.globalPosition),
                onDoubleTap: onDoubleTap,
                onTapUp: tap,
                child: SelectableScope(
                  id: selectableId,
                  // Space or Enter presses the item and acts once let go, as
                  // a button acts; Escape cancels.
                  child: KeyPress(
                    child: FocusableActionDetector(
                      focusNode: focusNode,
                      shortcuts: {
                        ...shortcuts,
                        const SingleActivator(LogicalKeyboardKey.contextMenu):
                            const SelectorContextMenuIntent(),
                        const SingleActivator(
                          LogicalKeyboardKey.f10,
                          shift: true,
                        ): const SelectorContextMenuIntent(),
                      },
                      onShowHoverHighlight: (hover) => isHovered.value = hover,
                      mouseCursor: SystemMouseCursors.click,
                      actions: {
                        SelectorContextMenuIntent:
                            CallbackAction<SelectorContextMenuIntent>(
                              onInvoke: (_) {
                                final anchor = anchorKey.currentContext
                                    ?.findRenderObject();
                                if (anchor is RenderBox && anchor.attached) {
                                  activateContext(
                                    anchor.localToGlobal(
                                      anchor.size.center(Offset.zero),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                        ActivateIntent: CallbackAction<ActivateIntent>(
                          onInvoke: (_) => choose(
                            throughTap: false,
                            (selection) => selection.selectOnly(selectableId),
                          ),
                        ),
                        ToggleIntent: CallbackAction<ToggleIntent>(
                          onInvoke: (_) => choose(
                            throughTap: false,
                            (selection) => selection.toggle(selectableId),
                          ),
                        ),
                        ExtendSelectionIntent:
                            CallbackAction<ExtendSelectionIntent>(
                              onInvoke: (intent) => extend(intent.direction),
                            ),
                      },
                      child: PixelScaleTransition(
                        pixelScale: focusPulse.drive(Tween(begin: 0, end: 15)),
                        child: _SelectorStateScope(
                          selected: isSelected,
                          selecting: selecting,
                          toggle: () => choose(
                            throughTap: true,
                            (selection) => selection.toggle(selectableId),
                          ),
                          child: HookBuilder(
                            builder: (context) {
                              return builder(
                                isSelected,
                                isFocused.value,
                                isHovered.value,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Describes how a selector activation entered the shared action pipeline.
class SelectedSelectorIntent extends Intent {
  const SelectedSelectorIntent({
    required this.selectableId,
    required this.focusNode,
    required this.throughTap,
    required this.throughActivateIntent,
  });

  final SelectableIdentifier selectableId;
  final FocusNode focusNode;

  /// Whether the activation originated from a pointer tap.
  final bool throughTap;

  /// Whether the activation originated from Flutter's activate intent.
  final bool throughActivateIntent;
}

/// What the nearest [Selector] shows, for its [SelectorCheck].
class _SelectorStateScope extends InheritedWidget {
  const _SelectorStateScope({
    required this.selected,
    required this.selecting,
    required this.toggle,
    required super.child,
  });

  final bool selected;
  final bool selecting;
  final VoidCallback toggle;

  @override
  bool updateShouldNotify(_SelectorStateScope oldWidget) =>
      selected != oldWidget.selected || selecting != oldWidget.selecting;
}

/// Where a [SelectorCheck] puts the check beside its item.
enum SelectorCheckPlacement {
  /// Before a row's content, which moves aside as the check grows in.
  leading,

  /// Over a card's top start corner.
  corner,
}

/// The check of the nearest [Selector]'s item: it grows in while the
/// selection is in select mode and shows whether the item is selected.
///
/// Clicking the check adds or removes the item, as Command or Control+click
/// does. The item stays the one focus stop and already reads as checked, so
/// the check takes no focus and says nothing itself.
class SelectorCheck extends StatelessWidget {
  const SelectorCheck({
    required this.child,
    this.placement = SelectorCheckPlacement.leading,
    super.key,
  });

  final SelectorCheckPlacement placement;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context
        .dependOnInheritedWidgetOfExactType<_SelectorStateScope>();
    final check = MotionSize(
      alignment: AlignmentDirectional.topStart,
      child: state == null || !state.selecting
          ? const SizedBox.shrink()
          : ExcludeSemantics(
              child: ExcludeFocus(
                child: SelectionCheck(
                  value: state.selected,
                  onChanged: state.toggle,
                ),
              ),
            ),
    );
    return switch (placement) {
      SelectorCheckPlacement.leading => Row(
        children: [
          check,
          Expanded(child: child),
        ],
      ),
      SelectorCheckPlacement.corner => Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          PositionedDirectional(top: 0, start: 0, child: check),
        ],
      ),
    };
  }
}
