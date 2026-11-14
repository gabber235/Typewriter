import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Conditional sections share one scroll surface and one focused action set.
class RealmInboxView extends StatelessWidget {
  const RealmInboxView({
    required this.state,
    required this.work,
    required this.onClose,
    required this.openLocation,
    required this.resourceLabel,
    required this.removedLabel,
    super.key,
  });
  final RealmInboxState state;
  final LocalWorkCommands work;
  final VoidCallback onClose;
  final Future<void> Function(skir.ValueLocation) openLocation;
  final String Function(skir.ResourceId) resourceLabel;

  /// Names a removed root by the record it was published from, since saved
  /// content no longer holds it.
  final String Function(skir.PublishedRoot) removedLabel;

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
        Button(
          face: ButtonFace.icon,
          icon: Icon(
            Icons.close,
            size: 20,
            color: context.colors.contentSecondary,
          ),
          label: "Close",
          tooltip: "Close",
          onPressed: onClose,
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

  Widget _publication(BuildContext context, ActionShortcut? publish) =>
      switch (state.publication) {
        ReadyRealmPublication() => Padding(
          key: const ValueKey("ready"),
          padding: EdgeInsets.only(top: context.spacing.space4),
          child: CommandButton(
            command: publish!,
            face: ButtonFace.filled,
            icon: const Icon(Icons.publish_rounded),
            label: "Publish",
            busyLabel: "Publishing",
          ),
        ),
        BlockedRealmPublication() => Padding(
          key: const ValueKey("blocked"),
          padding: EdgeInsets.only(top: context.spacing.space4),
          child: Row(
            children: [
              Icon(
                Icons.block,
                size: 18,
                color: context.colors.contentSecondary,
              ),
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
    // One command for the key and the button, offered only while Publish
    // shows. A failure lets CommandRuns jam the button and tell the author.
    final publish = switch (state.publication) {
      ReadyRealmPublication(:final command) => ActionShortcut.intent(
        id: "realm_inbox_publish",
        label: "Publish",
        description: "Publish the reviewed saved changes",
        intent: PrimaryActionIntent,
        priority: 100,
        run: ActionRun.press((_) => command.invoke()),
      ),
      _ => null,
    };
    return ManagedActionSet(
      shortcuts: [?publish],
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
                        sliver: EnterRun(
                          child: SliverMainAxisGroup(
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
                                  // The row is already one control, so it
                                  // holds; open focus lands on it.
                                  child: RowStop(
                                    role: RowRole.holder,
                                    child: _issue(context, issue),
                                  ),
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
                                itemBuilder: (context, change) => RowStop(
                                  role: RowRole.holder,
                                  child: _change(context, change),
                                ),
                              ),
                              AnimatedSliverList<skir.CompilationRoot>(
                                items: state.pendingRoots,
                                identity: (root) => root,
                                itemBuilder: (context, root) => PanelRow(
                                  padding: EdgeInsets.zero,
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
                                itemBuilder: (context, entry) => RowStop(
                                  role: RowRole.holder,
                                  child: _workRow(context, entry),
                                ),
                              ),
                              SliverAnimatedContent(
                                child: _publication(context, publish),
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
      return PanelRow(
        padding: EdgeInsets.zero,
        leading: Icon(
          Icons.error_outline,
          size: 18,
          color: context.theme.colorScheme.error,
        ),
        title: Text(submission.label),
        subtitle: Text(issue.message),
        trailing: submission.integrationFailed || submission.canReplay
            ? Button(
                label: submission.integrationFailed
                    ? "Refresh result"
                    : "Retry request",
                onPressed: () => work.retrySubmission(submission.id),
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
            style: context.text.sentence.copyWith(fontWeight: FontWeight.w600),
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
                  Button(
                    label: "Related: ${resourceLabel(location.resource)}",
                    onPressed: () => openLocation(location),
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
      skir.PublicationChange_rootUpdatedWrapper(:final value) => value,
      skir.PublicationChange_rootRemovedWrapper(:final value) => value.root,
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
    final title = switch (change) {
      skir.PublicationChange_rootRemovedWrapper(:final value) => removedLabel(
        value,
      ),
      _ => root == null ? label : resourceLabel(root.resource),
    };
    return PanelRow(
      padding: EdgeInsets.zero,
      label: title,
      leading: _icon(context, Icons.article_outlined, color),
      title: Text(title, style: context.theme.textTheme.titleSmall),
      trailing: root == null ? null : _badge(context, label, color),
      onPressed:
          root == null || change is skir.PublicationChange_rootRemovedWrapper
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
      PanelRow(
        padding: EdgeInsets.zero,
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
            Button(
              label: "Review draft",
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
                        Button(
                          label: "Close",
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                } finally {
                  review.release();
                }
              },
            ),
          if (entry.canSave)
            Button(label: "Apply", onPressed: () => work.save(entry.id)),
          if (entry.canRetry)
            Button(
              label: "Retry",
              busyLabel: "Retrying",
              onPressed: () => work.retry(entry.id),
            ),
          if (entry.canDiscard)
            CommandButton(
              command: discardWork(
                entry: entry.id,
                label: entry.label,
                discard: work.discard,
              ),
              label: "Discard",
            ),
        ],
      ),
    ],
  );
}
