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
    final controller = useMenuController();
    final anchorKey = useGlobalKey();
    final pendingContextPosition = useState<Offset?>(null);
    final contextTargets = useState<List<SelectableIdentifier>?>(null);
    final selection = ref.watch(selectionProvider);
    final selected = ref.watch(selectedProvider);

    final registeredOperations = SelectionOperationsRoot.of(context);
    final captured = contextTargets.value;
    final resources = captured
        ?.whereType<AuthoringResourceIdentifier>()
        .toList();
    final operations =
        resources != null &&
            resources.isNotEmpty &&
            resources.length == captured!.length &&
            resources.every((item) => item.scope == resources.first.scope)
        ? resourceSelectionOperationsFor(
            ref,
            resources.first.scope,
            resources.map((item) => item.resourceId),
          )
        : selectionOperationsFor(ref, context, selected.value);

    useFocusedChange(focusNode, ({required hasFocus}) {
      isFocused.value = hasFocus;
      if (!hasFocus) pendingContextPosition.value = null;
      onFocusChange?.call(hasFocus);
      return null;
    }, [focusNode, onFocusChange]);

    void activateContext(Offset globalPosition) {
      if (!ref.read(selectionProvider).contains(selectableId)) {
        ref.read(selectionProvider.notifier).selectAll([selectableId]);
      }
      contextTargets.value = List.of(ref.read(selectionProvider));
      focusNode.requestFocus();
      pendingContextPosition.value = globalPosition;
    }

    useEffect(
      () {
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
          controller.open(position: anchor.globalToLocal(position));
        });
        return () => active = false;
      },
      [pendingContextPosition.value, selection, selected, registeredOperations],
    );

    final focusAnimation = useAnimationController(
      duration: 200.ms,
      initialValue: 0.0,
    );

    useEffect(() {
      if (!isFocused.value) return null;
      if (focusAnimation.isAnimating) return null;
      focusAnimation.forward(from: 0.0);
      return null;
    }, [isFocused.value]);

    return KeyedSubtree(
      key: Key(selectableId.id),
      child: ContextMenuRegion(
        key: anchorKey,
        childFocusNode: focusNode,
        onClose: () => contextTargets.value = null,
        items: [
          if (operations.isNotEmpty)
            MenuItem.section(
              label: "Operations",
              items: [
                for (final operation in operations) operation.menuItem(ref),
              ],
            ),
        ],
        enableGestures: false,
        controller: controller,
        child: GestureDetector(
          onSecondaryTapUp: (details) =>
              activateContext(details.globalPosition),
          onLongPressStart: (details) =>
              activateContext(details.globalPosition),
          onDoubleTap: onDoubleTap,
          onTapUp: ContextMenuRegion.onTapUp(
            controller,
            onContextTap: (details) => activateContext(details.globalPosition),
            orElse: (_) {
              Actions.maybeInvoke(
                context,
                SelectedSelectorIntent(
                  selectableId: selectableId,
                  focusNode: focusNode,
                  throughTap: true,
                  throughActivateIntent: false,
                ),
              );
              ref.read(selectionProvider.notifier).select(selectableId);
              focusNode.requestFocus();
            },
          ),
          child: SelectableScope(
            id: selectableId,
            child: FocusableActionDetector(
              focusNode: focusNode,
              shortcuts: {
                ...shortcuts,
                const SingleActivator(LogicalKeyboardKey.contextMenu):
                    const SelectorContextMenuIntent(),
                const SingleActivator(LogicalKeyboardKey.f10, shift: true):
                    const SelectorContextMenuIntent(),
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
                ActivateIntent: CallbackAction(
                  onInvoke: (_) {
                    Actions.maybeInvoke(
                      context,
                      SelectedSelectorIntent(
                        selectableId: selectableId,
                        focusNode: focusNode,
                        throughTap: false,
                        throughActivateIntent: true,
                      ),
                    );
                    return ref
                        .read(selectionProvider.notifier)
                        .select(selectableId);
                  },
                ),
                ActivateAllIntent: CallbackAction(
                  onInvoke: (_) {
                    Actions.maybeInvoke(
                      context,
                      SelectedSelectorIntent(
                        selectableId: selectableId,
                        focusNode: focusNode,
                        throughTap: false,
                        throughActivateIntent: true,
                      ),
                    );
                    return ref
                        .read(selectionProvider.notifier)
                        .select(selectableId, isMultiSelect: true);
                  },
                ),
              },
              child: PixelScaleTransition(
                pixelScale: TweenSequence<double>([
                  TweenSequenceItem<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: 15,
                    ).curved(Curves.easeInOutCubicEmphasized),
                    weight: .5,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(
                      begin: 15,
                      end: 0,
                    ).curved(Curves.easeInOut),
                    weight: .5,
                  ),
                ]).animate(focusAnimation),
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

/// Opens the focused selectable's menu through its existing context action path.
class SelectorContextMenuIntent extends Intent {
  const SelectorContextMenuIntent();
}
