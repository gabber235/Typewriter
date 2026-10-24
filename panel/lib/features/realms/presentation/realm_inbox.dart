import "package:typewriter_panel/typewriter_panel.dart";

part "realm_inbox.g.dart";

@riverpod
AnchoredPopupController realmInboxPopup(Ref ref, AuthoringScope scope) {
  final controller = AnchoredPopupController();
  ref.onDispose(() {
    controller
      ..close(reason: PopupCloseReason.scopeChanged)
      ..dispose();
  });
  return controller;
}

/// The shortcut belongs to the active realm, independently of popup focus.
class RealmInboxShortcut extends HookConsumerWidget {
  const RealmInboxShortcut({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    final popup = scope == null
        ? null
        : ref.watch(realmInboxPopupProvider(scope));
    final router = ref.watch(navigationRouterProvider);
    useEffect(() {
      var path = router.currentPath;
      void changed() {
        if (path == router.currentPath) return;
        path = router.currentPath;
        popup?.close(reason: PopupCloseReason.navigated);
      }

      router.addListener(changed);
      return () {
        router.removeListener(changed);
        popup?.close(reason: PopupCloseReason.scopeChanged);
      };
    }, [router, popup]);
    final enabled =
        popup != null &&
        ref.watch(currentInteractionModeProvider) is NormalMode &&
        !ref.watch(realmInteractionProvider).suspended;
    final actions = <ActionShortcut>[
      if (enabled)
        ActionShortcut.intent(
          id: "realm_inbox_open",
          label: "Realm inbox",
          description: "Review realm issues and saved changes",
          intent: OpenRealmInboxIntent,
          priority: 20,
          onInvoke: (_) => popup.openFocused(),
        ),
    ];
    return RegisteredActionShortcuts(
      shortcuts: actions,
      child: ActionSet(shortcuts: actions, child: child),
    );
  }
}

/// Keeps Save activity available on routes outside a realm.
class WorkspaceActivityButton extends ConsumerWidget {
  const WorkspaceActivityButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    return scope == null
        ? const MutationActivityButton()
        : RealmInboxButton(key: ValueKey(scope), scope: scope);
  }
}

/// One stable trigger and popup owner across status and app bar size changes.
class RealmInboxButton extends HookConsumerWidget {
  const RealmInboxButton({required this.scope, super.key});
  final AuthoringScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(realmInboxProvider(scope));
    final displayed = useDeferredValue(state.buttonStatus);
    final popup = ref.watch(realmInboxPopupProvider(scope));
    final mobile = context.isMobile;
    useEffect(() {
      var sheetOpen = false;
      BuildContext? sheetContext;
      void changed() {
        if (mobile &&
            sheetOpen &&
            popup.presentation == PopupPresentation.closed) {
          final context = sheetContext;
          if (context != null && context.mounted) Navigator.pop(context);
          return;
        }
        if (!mobile ||
            sheetOpen ||
            popup.presentation != PopupPresentation.focused) {
          return;
        }
        sheetOpen = true;
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: context.theme.colorScheme.surfaceContainer
                .withValues(alpha: 0),
            builder: (context) {
              sheetContext = context;
              return SafeArea(
                minimum: EdgeInsets.all(context.spacing.space3),
                child: Material(
                  color: context.theme.colorScheme.surfaceContainer,
                  borderRadius: context.shapes.largeBorderRadius,
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .8,
                    ),
                    child: RealmInboxContent(
                      scope: scope,
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                ),
              );
            },
          ).whenComplete(() {
            sheetOpen = false;
            sheetContext = null;
            if (context.mounted) popup.close();
          }),
        );
      }

      popup.addListener(changed);
      return () => popup.removeListener(changed);
    }, [mobile, popup]);
    Widget trigger(VoidCallback open) => Semantics(
      liveRegion: true,
      child: AppBarControl.filled(
        contentBuilder: (context, compact) => AnimatedStatusContent(
          compact: compact,
          icon: Icon(
            displayed.icon,
            key: ValueKey(displayed.icon),
            size: 18,
            color: displayed.iconColor(context),
          ),
          label: displayed.label,
        ),
        tooltip: "Realm inbox (Shift + P in Normal mode)",
        semanticLabel: displayed.semanticLabel,
        style: displayed.buttonStyle(context),
        onPressed: open,
      ),
    );

    if (mobile) return trigger(popup.openFocused);
    return AnchoredPopup(
      controller: popup,
      targetAnchor: Alignment.bottomRight,
      popupAnchor: Alignment.topRight,
      offset: Offset(0, context.spacing.space2),
      maxWidth: 520,
      maxHeight: min(MediaQuery.sizeOf(context).height * .8, 640),
      builder: (context, open) => trigger(open),
      popupBuilder: (context, close) =>
          RealmInboxContent(scope: scope, onClose: close),
    );
  }
}

/// Provider boundary for the same live content on desktop and mobile.
class RealmInboxContent extends ConsumerWidget {
  const RealmInboxContent({
    required this.scope,
    required this.onClose,
    super.key,
  });
  final AuthoringScope scope;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(workingAuthoringDocumentProvider(scope)).value;
    return RealmInboxView(
      state: ref.watch(realmInboxProvider(scope)),
      work: ref.read(localWorkControllerProvider),
      resourceLabel: (id) => switch (document) {
        final document? =>
          resourceAppearanceIn(document.catalog, document, id)?.label ??
              "Removed resource",
        null => "Loading resource",
      },
      onClose: onClose,
      openLocation: (location) async {
        ref
            .read(realmInboxPopupProvider(scope))
            .close(reason: PopupCloseReason.navigated);
        final opened = await ref.read(
          openRealmInboxLocationProvider(scope, location).future,
        );
        if (!opened && context.mounted) {
          showErrorSnackBar(context, "This resource is no longer available");
        }
      },
    );
  }
}
