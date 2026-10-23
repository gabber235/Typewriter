import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
    final router = ref.watch(appRouterProvider);
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

/// Conditional sections share one scroll surface and one focused action set.
class RealmInboxView extends StatelessWidget {
  const RealmInboxView({
    required this.state,
    required this.work,
    required this.onClose,
    required this.openLocation,
    required this.resourceLabel,
    super.key,
  });
  final RealmInboxState state;
  final LocalWorkCommands work;
  final VoidCallback onClose;
  final Future<void> Function(skir.ValueLocation) openLocation;
  final String Function(skir.ResourceId) resourceLabel;

  Future<void> _publish(
    BuildContext context,
    RealmPublishCommand command,
  ) async {
    try {
      await command.invoke();
    } on Object catch (error) {
      if (context.mounted) showErrorSnackBar(context, error.toString());
    }
  }

  Widget _badge(BuildContext context, String text, Color color) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      borderRadius: context.shapes.smallBorderRadius,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space2,
        vertical: context.spacing.space1,
      ),
      child: Text(
        text,
        style: context.theme.textTheme.labelSmall?.copyWith(
          color: context.colors.contentPrimary,
        ),
      ),
    ),
  );

  Widget _icon(BuildContext context, IconData icon, Color color) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: context.shapes.mediumBorderRadius,
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: color, size: 20),
  );

  Widget _header(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.spacing.space5),
    child: Row(
      children: [
        Expanded(
          child: Text("Realm inbox", style: context.theme.textTheme.titleLarge),
        ),
        SizedBox(width: context.spacing.space2),
        IconButton(
          onPressed: onClose,
          tooltip: "Close",
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.close,
            size: 20,
            color: context.colors.contentSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _heading(BuildContext context, String text, int count, Color color) =>
      Padding(
        padding: EdgeInsets.only(bottom: context.spacing.space3),
        child: Row(
          children: [
            Text(
              text,
              style: context.theme.textTheme.titleSmall?.copyWith(
                color: context.theme.brightness == Brightness.dark
                    ? color
                    : context.colors.contentPrimary,
              ),
            ),
            SizedBox(width: context.spacing.space2),
            _badge(context, "$count", color),
          ],
        ),
      );

  Widget _empty(
    BuildContext context, {
    required String title,
    required String id,
  }) => Padding(
    key: ValueKey(id),
    padding: EdgeInsets.symmetric(vertical: context.spacing.space8),
    child: EmptyState(title: title, description: ""),
  );

  Widget _publication(BuildContext context) => switch (state.publication) {
    ReadyRealmPublication(:final command) => Padding(
      key: const ValueKey("ready"),
      padding: EdgeInsets.only(top: context.spacing.space4),
      child: LoadingButton.filledIcon(
        icon: const Icon(Icons.publish_rounded, size: 20),
        onPressed: () => _publish(context, command),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        label: const Text("Publish"),
      ),
    ),
    BlockedRealmPublication() => Padding(
      key: const ValueKey("blocked"),
      padding: EdgeInsets.only(top: context.spacing.space4),
      child: Row(
        children: [
          Icon(Icons.block, size: 18, color: context.colors.contentSecondary),
          SizedBox(width: context.spacing.space2),
          Text(
            "Publish blocked",
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: context.colors.contentSecondary,
            ),
          ),
        ],
      ),
    ),
    CheckingRealmPublication() => _message(
      context,
      "checking",
      "Checking saved content",
      null,
      Icons.sync,
    ),
    PublishingRealmPublication(:final data) => _message(
      context,
      "publishing",
      data.phase == skir.PublicationActivationPhase.storing
          ? "Preparing release"
          : "Activating release",
      null,
      Icons.cloud_upload_outlined,
    ),
    RequestActiveRealmPublication() => _message(
      context,
      "request",
      "Waiting for publication",
      null,
      Icons.sync,
    ),
    UncertainRealmPublication(:final message) => _message(
      context,
      "uncertain",
      "Publication outcome unknown",
      message,
      Icons.help_outline,
      context.colors.warning,
    ),
    UnavailableRealmPublication(:final message) => _message(
      context,
      "unavailable",
      "Publication review unavailable",
      message,
      Icons.error_outline,
      context.theme.colorScheme.error,
    ),
    CurrentRealmPublication()
        when state.issues.isEmpty && state.localWork.isEmpty =>
      _empty(context, id: "current", title: "Everything is published"),
    EmptyRealmPublication()
        when state.issues.isEmpty && state.localWork.isEmpty =>
      _empty(context, id: "empty", title: "No saved content to publish"),
    _ => const SizedBox.shrink(key: ValueKey("quiet")),
  };

  Widget _message(
    BuildContext context,
    String id,
    String title,
    String? description,
    IconData icon, [
    Color? color,
  ]) {
    final tone = color ?? context.colors.contentSecondary;
    return Padding(
      key: ValueKey(id),
      padding: EdgeInsets.only(top: context.spacing.space4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.withValues(alpha: .06),
          borderRadius: context.shapes.mediumBorderRadius,
          border: Border.all(color: tone.withValues(alpha: .18)),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _icon(context, icon, tone),
              SizedBox(width: context.spacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.theme.textTheme.titleSmall),
                    if (description != null) ...[
                      SizedBox(height: context.spacing.space1),
                      Text(
                        description,
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.contentSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = state.localWork
        .where((entry) => !entry.needsAttention && !entry.needsInput)
        .toList();
    return ManagedActionSet(
      shortcuts: [
        if (state.publication case ReadyRealmPublication(:final command))
          ActionShortcut.intent(
            id: "realm_inbox_publish",
            label: "Publish",
            description: "Publish the reviewed saved changes",
            intent: PrimaryActionIntent,
            priority: 100,
            onInvoke: (_) => _publish(context, command),
          ),
      ],
      child: Surface(
        color: context.colors.surface,
        foreground: context.colors.contentPrimary,
        secondaryForeground: context.colors.contentSecondary,
        child: ClipRRect(
          borderRadius: context.shapes.mediumBorderRadius,
          child: Material(
            color: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: context.shapes.mediumBorderRadius,
              side: BorderSide(
                color: context.colors.borderSubtle.withValues(alpha: .5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                Flexible(
                  child: CustomScrollView(
                    shrinkWrap: true,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          context.spacing.space5,
                          0,
                          context.spacing.space5,
                          context.spacing.space5,
                        ),
                        sliver: SliverStaggerScope(
                          sliver: SliverMainAxisGroup(
                            slivers: [
                              SliverAnimatedContent(
                                child: state.issues.isEmpty
                                    ? null
                                    : _heading(
                                        context,
                                        "Issues",
                                        state.issues.length,
                                        context.colors.warning,
                                      ),
                              ),
                              AnimatedSliverList<RealmInboxIssue>(
                                items: state.issues,
                                identity: (issue) => issue.identity,
                                itemBuilder: (context, issue) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: issue == state.issues.lastOrNull
                                        ? 0
                                        : context.spacing.space3,
                                  ),
                                  child: _issue(context, issue),
                                ),
                              ),
                              SliverAnimatedGap(
                                extent:
                                    state.issues.isEmpty ||
                                        (state.changes.isEmpty &&
                                            state.pendingRoots.isEmpty)
                                    ? 0
                                    : context.spacing.space4,
                              ),
                              SliverAnimatedContent(
                                child:
                                    state.changes.isEmpty &&
                                        state.pendingRoots.isEmpty
                                    ? null
                                    : _heading(
                                        context,
                                        "Saved changes",
                                        state.changes.length +
                                            state.pendingRoots.length,
                                        context.colors.brand,
                                      ),
                              ),
                              AnimatedSliverList<skir.PublicationChange>(
                                items: state.changes,
                                identity: (change) => change,
                                itemBuilder: _change,
                              ),
                              AnimatedSliverList<skir.CompilationRoot>(
                                items: state.pendingRoots,
                                identity: (root) => root,
                                itemBuilder: (context, root) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _icon(
                                    context,
                                    Icons.hourglass_empty,
                                    context.colors.contentSecondary,
                                  ),
                                  title: Text(
                                    resourceLabel(root.resource),
                                    style: context.theme.textTheme.titleSmall,
                                  ),
                                  trailing: _badge(
                                    context,
                                    "Needs fixes",
                                    context.colors.contentSecondary,
                                  ),
                                ),
                              ),
                              SliverAnimatedGap(
                                extent:
                                    local.isEmpty ||
                                        (state.issues.isEmpty &&
                                            state.changes.isEmpty &&
                                            state.pendingRoots.isEmpty)
                                    ? 0
                                    : context.spacing.space4,
                              ),
                              SliverAnimatedContent(
                                child: local.isEmpty
                                    ? null
                                    : _heading(
                                        context,
                                        "Local work",
                                        local.length,
                                        context.colors.contentSecondary,
                                      ),
                              ),
                              AnimatedSliverList<WorkEntryState>(
                                items: local,
                                identity: (entry) => entry.id,
                                itemBuilder: _workRow,
                              ),
                              SliverAnimatedContent(
                                child: _publication(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _issue(BuildContext context, RealmInboxIssue issue) {
    if (issue case RealmInboxWorkIssue(:final entry)) {
      return _workRow(context, entry);
    }
    if (issue case RealmInboxSubmissionIssue(:final submission)) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.error_outline,
          size: 18,
          color: context.theme.colorScheme.error,
        ),
        title: Text(submission.label),
        subtitle: Text(issue.message),
        trailing: submission.integrationFailed || submission.canReplay
            ? TextButton(
                onPressed: () => work.retrySubmission(submission.id),
                child: Text(
                  submission.integrationFailed
                      ? "Refresh result"
                      : "Retry request",
                ),
              )
            : null,
      );
    }
    final color = issue.severity == skir.DiagnosticSeverity.error
        ? context.theme.colorScheme.error
        : issue.severity == skir.DiagnosticSeverity.warning
        ? context.colors.warning
        : context.colors.contentSecondary;
    return SearchResultCard(
      color: color,
      prefix: Padding(
        padding: EdgeInsets.only(left: context.spacing.space2),
        child: _icon(
          context,
          issue.severity == skir.DiagnosticSeverity.error
              ? Icons.error_outline
              : issue.severity == skir.DiagnosticSeverity.warning
              ? Icons.warning_amber_outlined
              : Icons.info_outline,
          color,
        ),
      ),
      suffix: issue.primary == null
          ? null
          : Icon(
              Icons.chevron_right,
              size: 20,
              color: context.colors.contentSecondary,
            ),
      onTap: issue.primary == null ? null : () => openLocation(issue.primary!),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.message,
            style: context.theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (issue.primary case final location?) ...[
            SizedBox(height: context.spacing.space1),
            Text(
              "${resourceLabel(location.resource)} > ${location.path.issueLabel}",
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.colors.contentSecondary,
              ),
            ),
          ],
          SizedBox(height: context.spacing.space1),
          Text(
            issue.provenance,
            style: context.theme.textTheme.labelSmall?.copyWith(
              color: context.colors.contentSecondary,
            ),
          ),
          if (issue.related.isNotEmpty)
            Wrap(
              children: [
                for (final location in issue.related)
                  TextButton(
                    onPressed: () => openLocation(location),
                    child: Text("Related: ${resourceLabel(location.resource)}"),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _change(BuildContext context, skir.PublicationChange change) {
    final root = switch (change) {
      skir.PublicationChange_rootAddedWrapper(:final value) ||
      skir.PublicationChange_rootUpdatedWrapper(:final value) ||
      skir.PublicationChange_rootRemovedWrapper(:final value) => value,
      _ => null,
    };
    final label = switch (change) {
      skir.PublicationChange_rootAddedWrapper() => "Added",
      skir.PublicationChange_rootUpdatedWrapper() => "Updated",
      skir.PublicationChange_rootRemovedWrapper() => "Removed",
      skir.PublicationChange.requirementsChanged =>
        "Runtime requirements changed",
      _ => "Unknown change",
    };
    final color = switch (change) {
      skir.PublicationChange_rootAddedWrapper() => context.colors.success,
      skir.PublicationChange_rootRemovedWrapper() => context.colors.danger,
      _ => context.colors.brand,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _icon(context, Icons.article_outlined, color),
      title: Text(
        root == null ? label : resourceLabel(root.resource),
        style: context.theme.textTheme.titleSmall,
      ),
      trailing: root == null ? null : _badge(context, label, color),
      onTap: root == null || change is skir.PublicationChange_rootRemovedWrapper
          ? null
          : () => openLocation(
              skir.ValueLocation(
                resource: root.resource,
                path: skir.ValuePath(segments: const []),
              ),
            ),
    );
  }

  Widget _workRow(BuildContext context, WorkEntryState entry) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          entry.needsAttention ? Icons.error_outline : Icons.edit_outlined,
          size: 18,
        ),
        title: Text(entry.label),
        subtitle: Text(entry.phase),
      ),
      Wrap(
        children: [
          if (entry.canReview)
            TextButton(
              onPressed: () async {
                final review = work.review(entry.id);
                if (review == null) {
                  return;
                }
                try {
                  await showAdvancedDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(entry.label),
                      content: SizedBox(
                        width: 560,
                        child: SingleChildScrollView(
                          child: review.content.body,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                } finally {
                  review.release();
                }
              },
              child: const Text("Review draft"),
            ),
          if (entry.canSave)
            TextButton(
              onPressed: () => work.save(entry.id),
              child: const Text("Apply"),
            ),
          if (entry.canRetry)
            TextButton(
              onPressed: () => work.retry(entry.id),
              child: const Text("Retry"),
            ),
          if (entry.canDiscard)
            TextButton(
              onPressed: () => work.discard(entry.id),
              child: const Text("Discard"),
            ),
        ],
      ),
    ],
  );
}
