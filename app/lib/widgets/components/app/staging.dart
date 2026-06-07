import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";
import "package:typewriter/hooks/rive_statemachines.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/staging.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/widgets/components/general/iconify.dart";

class StagingIndicator extends HookConsumerWidget {
  const StagingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stagingStateProvider);
    final l10n = ref.watch(l10nProvider);

    final stateLabel = switch (state) {
      StagingState.production => l10n.stagingProduction,
      StagingState.staging => l10n.stagingStaging,
      StagingState.publishing => l10n.stagingPublishing,
    };

    return Stack(
      children: [
        DottedBorder(
          borderType: BorderType.RRect,
          color:
              state == StagingState.staging ? state.color : Colors.transparent,
          strokeWidth: 2,
          dashPattern: const [5, 5],
          radius: const Radius.circular(8),
          padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Icon(),
              const SizedBox(width: 8),
              Text(
                stateLabel,
                style: TextStyle(
                  color: state.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (state == StagingState.staging)
          const Positioned.fill(child: _PublishButton()),
      ],
    );
  }
}

class _Icon extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stagingStateProvider);
    final stateMachine = useRiveStateMachine("status");

    useEffect(
      () {
        stateMachine.setNumber("state", state.index.toDouble());
        return null;
      },
      [state, stateMachine.hasController],
    );

    return SizedBox(
      height: 24,
      width: 24,
      child: RepaintBoundary(
        child: RiveAnimation.asset(
          "assets/status.riv",
          onInit: stateMachine.init,
        ),
      ),
    );
  }
}

class _PublishButton extends HookConsumerWidget {
  const _PublishButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final hovering = useState(false);
    return MouseRegion(
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: Transform.scale(
        scale: 1.07,
        child: ClipRRect(
          child: AnimatedSlide(
            duration: hovering.value ? 300.ms : 100.ms,
            curve: hovering.value ? Curves.easeOutExpo : Curves.easeOut,
            offset: hovering.value ? Offset.zero : const Offset(0, -1),
            child: Material(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => ref.read(communicatorProvider).publish(),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Iconify(
                        TWIcons.cloudUpload,
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Text(
                        l10n.publish,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
