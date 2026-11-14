import "package:typewriter_panel/typewriter_panel.dart";

part "mutation_activity_details.dart";
part "mutation_activity_card.dart";

/// Displays the current scoped mutation activity and opens its details.
///
/// The button observes the immutable activity read model while commands are
/// resolved through the stable local work controller.
class MutationActivityButton extends ConsumerWidget {
  const MutationActivityButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MutationActivityView(
    state: ref.watch(localWorkProvider),
    controller: ref.read(localWorkControllerProvider),
  );
}

/// Renders mutation activity for an explicit state and command owner.
///
/// This split lets route shells use Riverpod and tests or short lived sessions
/// provide their own state stream without changing activity behavior.
class MutationActivityView extends ConsumerWidget {
  const MutationActivityView({
    required this.state,
    required this.controller,
    super.key,
  });
  final LocalWorkState state;
  final LocalWorkCommands controller;

  Future<void> _showMobileActivity(BuildContext context) =>
      context.showPanelSheet<void>(
        (context) => SheetCard(
          maxHeight: min(MediaQuery.sizeOf(context).height * .75, 580),
          child: _ActivityDetails(
            state: state,
            controller: controller,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = state.entries.values.toList();
    final failures = [
      for (final notice in ref.watch(noticesProvider))
        if (notice.tone == NoticeTone.failure && !notice.toasting) notice,
    ];
    final unread = failures.where((notice) => notice.unread).length;
    final phase = MutationActivityPhase.resolve(state.submissions, drafts);
    // Failures name the button while some wait unread, or while nothing
    // else has a state to show.
    final failing =
        failures.isNotEmpty &&
        (unread > 0 || phase == MutationActivityPhase.idle);
    final label = failing
        ? "${failures.length} failed"
        : phase.label(drafts.length);
    final icon = Icon(failing ? Icons.error_outline : phase.icon, size: 18);
    final color = !failing
        ? phase.textColor(context)
        : unread > 0
        ? MutationActivityPhase.needsAttention.textColor(context)
        : context.colors.contentSecondary;
    void opened(VoidCallback show) {
      ref.read(noticesProvider.notifier).readAll();
      show();
    }

    Widget trigger(BuildContext context, VoidCallback show) => ElasticSwitcher(
      child: phase == MutationActivityPhase.idle && failures.isEmpty
          ? null
          : Padding(
              key: const ValueKey("activity"),
              padding: context.isMobile
                  ? EdgeInsets.symmetric(horizontal: context.spacing.space2)
                  : EdgeInsets.zero,
              // The control names itself; the live region only announces
              // when its label changes.
              child: Semantics(
                liveRegion: true,
                child: ToastLandingTarget(
                  child: AppBarControl(
                    face: ButtonFace.outlined,
                    tooltip: label,
                    semanticLabel: label,
                    contentBuilder: (context, compact) => AppBarControlContent(
                      compact: compact,
                      icon: icon,
                      label: label,
                      rippling: phase.isSaving,
                    ),
                    color: color,
                    onPressed: () => opened(show),
                  ),
                ),
              ),
            ),
    );
    if (context.isMobile) {
      return trigger(context, () => _showMobileActivity(context));
    }
    return AnchoredPopup(
      targetAnchor: Alignment.bottomRight,
      popupAnchor: Alignment.topRight,
      offset: Offset(0, context.spacing.space2),
      maxHeight: min(MediaQuery.sizeOf(context).height * .75, 580),
      popupBuilder: (context, close) => SizedBox(
        width: double.infinity,
        child: _ActivityDetails(
          state: state,
          controller: controller,
          onClose: close,
        ),
      ),
      builder: trigger,
    );
  }
}

/// Adapts a [ScopedWorkSession] stream to [MutationActivityView].
///
/// The initial snapshot is rendered immediately. Later snapshots replace it
/// until the session is disposed by its owner.
class ScopedWorkSessionActivityView extends StatelessWidget {
  const ScopedWorkSessionActivityView({required this.controller, super.key});

  final ScopedWorkSession controller;

  @override
  Widget build(BuildContext context) => StreamBuilder<LocalWorkState>(
    initialData: controller.state,
    stream: controller.changes,
    builder: (context, snapshot) => MutationActivityView(
      state: snapshot.requireData,
      controller: controller,
    ),
  );
}

extension _ActivityAppearance on MutationActivityPhase {
  String label(int drafts) => switch (this) {
    MutationActivityPhase.idle => "Save activity",
    MutationActivityPhase.pending => "Pending",
    MutationActivityPhase.saving => "Saving",
    MutationActivityPhase.savingWithAttention => "Saving. Needs attention",
    MutationActivityPhase.needsAttention => "Needs attention",
    MutationActivityPhase.needsInput => "Needs input",
    MutationActivityPhase.drafts =>
      "$drafts ${drafts == 1 ? "draft" : "drafts"}",
    MutationActivityPhase.saved => "Saved",
  };

  Color color(BuildContext context) => switch (this) {
    MutationActivityPhase.needsAttention ||
    MutationActivityPhase.savingWithAttention => context.colors.danger,
    MutationActivityPhase.needsInput ||
    MutationActivityPhase.drafts => context.colors.warning,
    MutationActivityPhase.saved => context.colors.success,
    MutationActivityPhase.saving ||
    MutationActivityPhase.pending => context.colors.brand,
    MutationActivityPhase.idle => context.colors.contentSecondary,
  };

  /// The label colour: the phase hue as text, 4.5:1 on every surface and on
  /// the 12% tint behind it.
  Color textColor(BuildContext context) => switch (this) {
    MutationActivityPhase.idle => context.colors.contentSecondary,
    _ => context.colors.textOf(
      color(context),
      over: Color.alphaBlend(
        color(context).withValues(alpha: .12),
        context.colors.surface,
      ),
    ),
  };

  IconData get icon => switch (this) {
    MutationActivityPhase.needsAttention ||
    MutationActivityPhase.savingWithAttention => Icons.error_outline,
    MutationActivityPhase.needsInput => Icons.rule_outlined,
    MutationActivityPhase.drafts => Icons.edit_outlined,
    MutationActivityPhase.pending || MutationActivityPhase.saving => Icons.sync,
    MutationActivityPhase.saved ||
    MutationActivityPhase.idle => Icons.cloud_done_outlined,
  };
}
