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
///
/// On a [SelectionSurface] with its own [SurfaceSelection], every gesture
/// goes to that selection instead, the item reads as selected by it, and it
/// has no context menu of page operations.
class Selector extends HookConsumerWidget {
  const Selector({
    required this.selectableId,
    required this.builder,
    required this.focusNode,
    this.onFocusChange,
    this.onDoubleTap,
    this.shortcuts = const {},
    this.link,
    super.key,
  });

  /// Lets [SelectorLinkRegion]s outside this selector, such as the other
  /// cells of a table row, take the same pointer gestures.
  final SelectorLink? link;

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
    final surface = SelectionSurface.maybeOf(context);
    final owned = surface?.selection;
    useListenable(owned);
    final isSelected =
        owned?.contains(selectableId) ??
        ref.watch<bool>(isSelectedProvider(selectableId));
    final isFocused = useState(false);
    final isHovered = useState(false);
    final controller = useMemoized(AnchoredPopupController.new);
    useEffect(() => controller.dispose, [controller]);
    final anchorKey = useGlobalKey();
    final pendingContextPosition = useState<Offset?>(null);
    final contextTargets = useState<List<SelectableIdentifier>?>(null);
    final selection = ref.watch(selectionProvider);
    final selected = ref.watch(selectedProvider);
    // Select mode shows checks only on a surface holding a selected item,
    // so the rest of the page stays as it was.
    final selecting = owned != null
        ? owned.showsChecks
        : ref.watch(selectModeProvider) &&
              (surface == null ? isSelected : selection.any(surface.contains));
    useEffect(() => surface?.register(context, selectableId), [
      surface,
      selectableId,
    ]);

    // A revealed item takes focus after the frame, once its route is
    // current, so neither the page's open focus nor a closing search keeps
    // it.
    final landing = ref.watch(
      selectionLandingProvider.select((id) => id == selectableId),
    );
    final current = ModalRoute.isCurrentOf(context) ?? true;
    useEffect(() {
      if (!landing || !current) return null;
      var active = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!active || !context.mounted) return;
        ref.read(selectionLandingProvider.notifier).take(selectableId);
        focusNode.requestFocus();
      });
      return () => active = false;
    }, [landing, current, focusNode]);

    // A surface's own selection offers no page operations.
    final source = owned == null ? SelectionOperationsRoot.of(context) : null;
    final captured = contextTargets.value;
    final operations = source == null
        ? const <SelectionOperation>[]
        : (captured == null
                  ? null
                  : source.operationsForTargets(ref, captured)) ??
              source.operationsFor(ref, selected.value ?? const []);

    // The menu acts on the targets captured when it opened, resolved when
    // an entry runs.
    List<Selectable> menuTargets(WidgetRef ref) => [
      for (final id in captured ?? const <SelectableIdentifier>[])
        ?ref.read(selectableResolutionProvider(id)).value,
    ];

    useFocusedChange(focusNode, ({required hasFocus}) {
      isFocused.value = hasFocus;
      if (!hasFocus) pendingContextPosition.value = null;
      onFocusChange?.call(hasFocus);
      return null;
    }, [focusNode, onFocusChange]);

    void activateContext(Offset globalPosition) {
      if (owned != null) return;
      if (!ref.read(selectionProvider).contains(selectableId)) {
        ref.read(selectionProvider.notifier).selectOnly(selectableId);
      }
      contextTargets.value = List.of(ref.read(selectionProvider));
      focusNode.requestFocus();
      pendingContextPosition.value = globalPosition;
    }

    // Announces the choice to the surface, then changes the selection.
    void choose(void Function() change, {required bool throughTap}) {
      Actions.maybeInvoke(
        context,
        SelectedSelectorIntent(
          selectableId: selectableId,
          focusNode: focusNode,
          throughTap: throughTap,
          throughActivateIntent: !throughTap,
        ),
      );
      change();
    }

    List<SelectableIdentifier> order() => surface?.order ?? [selectableId];

    // The gestures, sent to the surface's own selection or else the page
    // selection.
    void selectOnly() => owned != null
        ? owned.choose(selectableId)
        : ref.read(selectionProvider.notifier).selectOnly(selectableId);
    void toggle() => owned != null
        ? owned.toggle(selectableId)
        : ref.read(selectionProvider.notifier).toggle(selectableId);
    void selectRange(
      SurfaceSelection? target,
      SelectableIdentifier to,
      List<SelectableIdentifier> items, {
      SelectableIdentifier? from,
    }) => target != null
        ? target.selectRange(to, order: items, from: from)
        : ref
              .read(selectionProvider.notifier)
              .selectRange(to, order: items, from: from);

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
      choose(throughTap: true, () {
        if (held.range) {
          selectRange(owned, selectableId, order());
        } else if (held.toggle) {
          toggle();
        } else {
          selectOnly();
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
        final reached = SelectionSurface.ofPrimaryFocus();
        selectRange(
          reached?.selection ?? (reached == null ? owned : null),
          to,
          reached?.order ?? order(),
          from: selectableId,
        );
      });
    }

    link?._target = (
      owner: context,
      down: () => pressed.value = modifiers(),
      tap: tap,
      context: activateContext,
    );
    useEffect(() {
      final current = link;
      return () {
        current?._release(context);
      };
    }, [link]);

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
            items: selectionOperationMenuItems(operations, ref, menuTargets),
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
                          onInvoke: (_) =>
                              choose(throughTap: false, selectOnly),
                        ),
                        ToggleIntent: CallbackAction<ToggleIntent>(
                          onInvoke: (_) => choose(throughTap: false, toggle),
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
                          toggle: () => choose(throughTap: true, toggle),
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

/// Joins widgets outside a [Selector] to its pointer gestures: the cells of a
/// table row beside the cell that holds the selector.
///
/// One link belongs to one selector; each [SelectorLinkRegion] holding it
/// selects, toggles, extends and opens the context menu as a press on the
/// selector itself does.
final class SelectorLink {
  /// The gestures of the selector holding the link, and that selector's
  /// context; null while no selector holds it.
  ({
    BuildContext owner,
    VoidCallback down,
    void Function(TapUpDetails details) tap,
    void Function(Offset globalPosition) context,
  })?
  _target;

  /// Lets go of the selector of [owner], unless another selector holds the
  /// link by now.
  void _release(BuildContext owner) {
    if (_target?.owner == owner) _target = null;
  }
}

/// Takes the pointer gestures of the [Selector] that holds [link].
class SelectorLinkRegion extends StatelessWidget {
  const SelectorLinkRegion({
    required this.link,
    required this.child,
    super.key,
  });

  final SelectorLink link;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) => link._target?.down(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => link._target?.tap(details),
          onSecondaryTapUp: (details) =>
              link._target?.context(details.globalPosition),
          onLongPressStart: (details) =>
              link._target?.context(details.globalPosition),
          child: child,
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
class SelectorCheck extends HookWidget {
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
    // The check's share of its size follows the motion, intrinsic size
    // included, so a column sized to its content grows and shrinks with
    // the check instead of jumping to its final width.
    final shown = useMotion(
      MotionToken.surfaceIn,
      state != null && state.selecting ? 1 : 0,
    ).value.clamp(0.0, 1.0);
    final check = shown == 0
        ? const SizedBox.shrink()
        : ClipRect(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              widthFactor: shown,
              heightFactor: shown,
              child: ExcludeSemantics(
                child: ExcludeFocus(
                  child: SelectionCheck(
                    value: state?.selected ?? false,
                    onChanged: state?.toggle,
                  ),
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
