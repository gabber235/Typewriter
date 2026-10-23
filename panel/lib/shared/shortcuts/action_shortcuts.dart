import "package:typewriter_panel/typewriter_panel.dart";

part "action_shortcuts.freezed.dart";
part "action_shortcuts.g.dart";

/// Callback invoked by an action with the caller's Riverpod [WidgetRef].
typedef ActionInvoke = FutureOr<void> Function(WidgetRef ref);

/// A user action that can be invoked by a shortcut and optionally shown in the
/// global action row.
///
/// Use the activator constructor for local keys that are not part of the panel
/// map. Use [ActionShortcut.intent] when the action should share the panel's
/// canonical key map. An action is callable only when it has both a callback
/// and at least one activator. IDs are global within the current provider and
/// higher priority wins in the visible registry when mounted sets share an ID.
/// Keyboard dispatch follows Flutter's nearest shortcut and action scopes.
@freezed
abstract class ActionShortcut with _$ActionShortcut {
  @Assert("id != \"\"", "ID must not be empty.")
  const factory ActionShortcut({
    required String id,
    required String label,
    required String description,
    required List<ShortcutActivator> activators,
    required int priority,
    Widget? icon,
    ActionInvoke? onInvoke,
    @Default(true) bool show,
    @Default(true) bool registerShortcut,
    GlobalKey? owner,
  }) = ActivatorActionShortcut;

  @Assert("id != \"\"", "ID must not be empty.")
  const factory ActionShortcut.intent({
    required String id,
    required String label,
    required String description,
    required Type intent,
    required int priority,
    Widget? icon,
    ActionInvoke? onInvoke,
    @Default(true) bool show,
    @Default(true) bool registerShortcut,
    GlobalKey? owner,
  }) = IntentActionShortcut;

  const ActionShortcut._();

  /// Whether this action has enough information to be invoked.
  bool get canInvoke {
    return onInvoke != null && shortcuts.isNotEmpty;
  }

  List<ShortcutActivator> get shortcuts {
    return switch (this) {
      ActivatorActionShortcut(:final activators) => activators,
      IntentActionShortcut(:final intent) => shortcutsFor(intent),
      ActionShortcut() => [],
    };
  }
}

/// Riverpod registry of mounted action sets and their winning actions.
///
/// Each action set owns its registration through a [GlobalKey]. Re registering
/// replaces that set's previous entries, while [sweep] removes entries whose
/// owner is no longer mounted. The registry supplies the visible `ActionRow`;
/// keyboard handlers are installed separately by [RegisteredActionShortcuts].
@riverpod
class ActionShortcuts extends _$ActionShortcuts {
  @override
  Map<String, ActionShortcut> build() => {};

  /// Replaces the entries owned by [key] and merges the supplied actions.
  ///
  /// When IDs collide, the action with the greater [ActionShortcut.priority]
  /// remains registered. Equal priorities favor the new registration.
  void register(GlobalKey key, List<ActionShortcut> shortcuts) {
    final updated = Map<String, ActionShortcut>.from(state)
      // We know every shortcut that was managed by this global key is now invalid.
      ..removeWhere((id, shortcut) => shortcut.owner == key);

    if (shortcuts.isEmpty) {
      state = updated;
      return;
    }

    for (final shortcut in shortcuts) {
      final withOwner = shortcut.copyWith(owner: key);
      final current = updated[withOwner.id];
      if (current == null || withOwner.priority >= current.priority) {
        updated[withOwner.id] = withOwner;
      }
    }

    state = updated;
  }

  /// Retires an owner after unmount, including when its provider scope closes.
  void unregister(GlobalKey key) {
    if (ref.mounted) register(key, const []);
  }

  /// Removes registered actions whose owning widget has unmounted.
  void sweep() {
    if (state.isEmpty) return;
    final updated = Map<String, ActionShortcut>.from(state)
      ..removeWhere(
        (id, shortcut) =>
            shortcut.owner != null && shortcut.owner!.currentContext == null,
      );
    state = updated;
  }

  @override
  bool updateShouldNotify(
    Map<String, ActionShortcut> previous,
    Map<String, ActionShortcut> next,
  ) {
    return !mapEquals(previous, next);
  }
}

/// Keeps the global action registry free of unmounted owners.
///
/// Place this above action sets. It watches the registry and schedules a sweep
/// after each relevant frame, avoiding provider mutation during widget build.
class GlobalActionsManager extends HookConsumerWidget {
  const GlobalActionsManager({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(actionShortcutsProvider);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(actionShortcutsProvider.notifier).sweep();
      });
      return null;
    });
    return child;
  }
}

/// Enables actions only while this subtree owns focus.
///
/// This is the usual wrapper for feature actions. Focused sets register
/// keyboard actions and appear in `ActionRow`; unfocused sets contribute
/// neither, preventing inactive surfaces from handling the same key.
class ManagedActionSet extends HookConsumerWidget {
  const ManagedActionSet({required this.shortcuts, this.child, super.key});
  final List<ActionShortcut> shortcuts;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFocus = useState(false);
    return RegisteredActionShortcuts(
      shortcuts: hasFocus.value ? shortcuts : [],
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (focus) => hasFocus.value = focus,
        child: ActionSet(
          shortcuts: hasFocus.value ? shortcuts : [],
          child: child,
        ),
      ),
    );
  }
}

/// Installs callable actions in Flutter's [Shortcuts] and [Actions] layers.
///
/// The widget registers only actions with callbacks and enabled registration.
/// Intent actions reuse [typewriterShortcuts], while activator actions define
/// their own local key map.
class RegisteredActionShortcuts extends HookConsumerWidget {
  const RegisteredActionShortcuts({
    required this.shortcuts,
    required this.child,
    super.key,
  });
  final List<ActionShortcut> shortcuts;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regKey = useGlobalKey(debugLabel: "ShortcutActionSet");
    final callableShortcuts = useMemoized(
      () => shortcuts.where((s) => s.canInvoke && s.registerShortcut).toList(),
      [shortcuts],
    );

    return Shortcuts(
      key: regKey,
      shortcuts: {
        for (final action
            in callableShortcuts.whereType<ActivatorActionShortcut>())
          for (final activator in action.activators)
            activator: _ActionIntent(action),
        for (final action
            in callableShortcuts.whereType<IntentActionShortcut>())
          for (final activator in action.shortcuts)
            activator: typewriterShortcuts[activator]!,
      },
      child: Actions(
        actions: {
          _ActionIntent: CallbackAction<_ActionIntent>(
            onInvoke: (intent) {
              return intent.action.onInvoke!.call(ref);
            },
          ),
          for (final action
              in callableShortcuts.whereType<IntentActionShortcut>())
            action.intent: action.createCallbackAction(ref),
        },
        child: child,
      ),
    );
  }
}

class _ActionIntent extends Intent {
  const _ActionIntent(this.action);
  final ActionShortcut action;
}

final _intentActionFactories =
    <Type, Action<Intent> Function(ActionInvoke onInvoke, WidgetRef ref)>{
      ActivateIntent: (onInvoke, ref) =>
          CallbackAction<ActivateIntent>(onInvoke: (_) => onInvoke(ref)),
      ActivateAllIntent: (onInvoke, ref) =>
          CallbackAction<ActivateAllIntent>(onInvoke: (_) => onInvoke(ref)),
      CancelIntent: (onInvoke, ref) =>
          CallbackAction<CancelIntent>(onInvoke: (_) => onInvoke(ref)),
      DeleteIntent: (onInvoke, ref) =>
          CallbackAction<DeleteIntent>(onInvoke: (_) => onInvoke(ref)),
      DismissIntent: (onInvoke, ref) =>
          CallbackAction<DismissIntent>(onInvoke: (_) => onInvoke(ref)),
      FirstItemIntent: (onInvoke, ref) =>
          CallbackAction<FirstItemIntent>(onInvoke: (_) => onInvoke(ref)),
      LastItemIntent: (onInvoke, ref) =>
          CallbackAction<LastItemIntent>(onInvoke: (_) => onInvoke(ref)),
      PrimaryActionIntent: (onInvoke, ref) =>
          CallbackAction<PrimaryActionIntent>(onInvoke: (_) => onInvoke(ref)),
      OpenRealmInboxIntent: (onInvoke, ref) =>
          CallbackAction<OpenRealmInboxIntent>(onInvoke: (_) => onInvoke(ref)),
      OpenSearchIntent: (onInvoke, ref) =>
          CallbackAction<OpenSearchIntent>(onInvoke: (_) => onInvoke(ref)),
    };

extension on IntentActionShortcut {
  Action<Intent> createCallbackAction(WidgetRef ref) {
    final factory = _intentActionFactories[intent];
    if (factory == null) {
      throw UnsupportedError("No callback action factory for $intent.");
    }
    return factory(onInvoke!, ref);
  }
}

/// Publishes [shortcuts] in the visible action registry independently of focus.
///
/// Use this for actions that belong to an always active surface. Use
/// [ManagedActionSet] when registration must follow subtree focus. This widget
/// does not install keyboard handlers; [RegisteredActionShortcuts] owns those.
class ActionSet extends HookConsumerWidget {
  const ActionSet({required this.shortcuts, this.child, super.key});
  final List<ActionShortcut> shortcuts;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regKey = useGlobalKey(debugLabel: "ActionSet");
    final registry = ref.read(actionShortcutsProvider.notifier);
    useEffect(
      () => () {
        scheduleMicrotask(() {
          registry.unregister(regKey);
        });
      },
      [registry, regKey],
    );
    useDelayedExecution(() {
      if (!context.mounted) return;
      ref.read(actionShortcutsProvider.notifier).register(regKey, shortcuts);
    }, [regKey, shortcuts]);
    return KeyedSubtree(key: regKey, child: child ?? const SizedBox.shrink());
  }
}
