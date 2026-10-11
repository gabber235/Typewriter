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
class MutationActivityView extends StatelessWidget {
  const MutationActivityView({
    required this.state,
    required this.controller,
    super.key,
  });
  final LocalWorkState state;
  final LocalWorkCommands controller;

  Future<void> _showMobileActivity(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SafeArea(
          minimum: EdgeInsets.all(context.spacing.space3),
          child: Material(
            color: context.theme.colorScheme.surfaceContainer,
            borderRadius: context.shapes.largeBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: min(MediaQuery.sizeOf(context).height * .75, 580),
              ),
              child: _ActivityDetails(
                state: state,
                controller: controller,
                onClose: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final drafts = state.entries.values.toList();
    final phase = MutationActivityPhase.resolve(state.submissions, drafts);
    final label = phase.label(drafts.length);
    final color = phase.color(context);
    final icon = phase.isSaving
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Icon(phase.icon, size: 18);
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
      builder: (context, show) => ElasticSwitcher(
        child: phase == MutationActivityPhase.idle
            ? null
            : Padding(
                key: const ValueKey("activity"),
                padding: context.isMobile
                    ? EdgeInsets.symmetric(horizontal: context.spacing.space2)
                    : EdgeInsets.zero,
                child: Semantics(
                  liveRegion: true,
                  label: label,
                  child: context.isMobile
                      ? IconButton(
                          tooltip: label,
                          style: IconButton.styleFrom(
                            foregroundColor: color,
                            backgroundColor: color.withValues(alpha: .12),
                          ),
                          onPressed: () => _showMobileActivity(context),
                          icon: icon,
                        )
                      : TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: color,
                            backgroundColor: color.withValues(alpha: .12),
                          ),
                          onPressed: show,
                          icon: icon,
                          label: Text(label),
                        ),
                ),
              ),
      ),
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
    MutationActivityPhase.savingWithAttention =>
      context.theme.colorScheme.error,
    MutationActivityPhase.needsInput ||
    MutationActivityPhase.drafts => context.colors.warning,
    MutationActivityPhase.saved => context.colors.success,
    MutationActivityPhase.saving ||
    MutationActivityPhase.pending => context.theme.colorScheme.primary,
    MutationActivityPhase.idle => context.colors.contentSecondary,
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
