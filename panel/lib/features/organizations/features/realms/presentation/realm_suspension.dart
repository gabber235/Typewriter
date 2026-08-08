import "dart:ui";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class RealmSuspensionBarrier extends StatelessWidget {
  const RealmSuspensionBarrier({
    required this.interaction,
    required this.child,
    this.realm,
    this.onRetry,
    super.key,
  });

  final RealmInteractionState interaction;
  final Service? realm;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final suspended = interaction.suspended;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ExcludeInteraction(excluding: suspended, child: child),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !suspended,
            child: ElasticSwitcher(
              child: suspended
                  ? _RealmSuspensionVeil(
                      key: ValueKey(interaction.connectionState),
                      connectionState: interaction.connectionState,
                      realm: realm,
                      onRetry: onRetry,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class RealmSuspensionInline extends StatelessWidget {
  const RealmSuspensionInline({
    required this.suspended,
    required this.child,
    super.key,
  });

  final bool suspended;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return ExcludeInteraction(
      excluding: suspended,
      child: AnimatedOpacity(
        opacity: suspended ? 0.42 : 1,
        duration: duration,
        child: child,
      ),
    );
  }
}

class _RealmSuspensionVeil extends StatelessWidget {
  const _RealmSuspensionVeil({
    required this.connectionState,
    required this.realm,
    required this.onRetry,
    super.key,
  });

  final RealmConnectionState connectionState;
  final Service? realm;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _semanticLabel,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.spacing.space4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _ConnectionCard(
                  connectionState: connectionState,
                  realm: realm,
                  onRetry: onRetry,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel => switch (connectionState) {
    RealmConnectionState.checking => "Checking realm connection",
    RealmConnectionState.offline =>
      "Realm connection lost. Changes are paused.",
    RealmConnectionState.unavailable => "Realm unavailable",
    RealmConnectionState.notSelected || RealmConnectionState.online => "",
  };
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.connectionState,
    required this.realm,
    required this.onRetry,
  });

  final RealmConnectionState connectionState;
  final Service? realm;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _content;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 24,
      shadowColor: context.colors.shadow.withValues(alpha: 0.28),
      borderRadius: context.shapes.largeBorderRadius,
      clipBehavior: Clip.hardEdge,
      child: Surface(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Column(
          children: [
            if (connectionState == RealmConnectionState.checking)
              LinearProgressIndicator(backgroundColor: Colors.transparent),

            Padding(
              padding: EdgeInsets.all(context.spacing.space6),
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      _ConnectionMark(connectionState: connectionState),
                      Spacer(),
                      if (connectionState == RealmConnectionState.offline &&
                          realm != null) ...[
                        SizedBox(height: context.spacing.space4),
                        StatusIndicator(
                          isOnline: false,
                          lastSeen: realm!.lastSeen,
                          dotColor: context.colors.offline,
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                      if (connectionState == RealmConnectionState.unavailable &&
                          onRetry != null) ...[
                        SizedBox(height: context.spacing.space4),
                        OutlinedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Check again"),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: context.spacing.space4),
                  Text(content.title, style: theme.textTheme.headlineSmall),
                  SizedBox(height: context.spacing.space2),
                  Text(
                    content.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String title, String description})
  get _content => switch (connectionState) {
    RealmConnectionState.checking => (
      title: "Checking realm connection",
      description: "Hold on while we confirm that this realm is online.",
    ),
    RealmConnectionState.offline => (
      title: "Realm connection lost",
      description:
          "Changes to '${realm?.displayName ?? "this realm"}' are paused. Everything will resume automatically when the connection returns.",
    ),
    RealmConnectionState.unavailable => (
      title: "Realm unavailable",
      description:
          "We could not confirm this realm is available. Check again or choose another realm.",
    ),
    RealmConnectionState.notSelected || RealmConnectionState.online => (
      title: "Realm online",
      description: "The realm is ready.",
    ),
  };
}

class _ConnectionMark extends StatelessWidget {
  const _ConnectionMark({required this.connectionState});

  final RealmConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final color = switch (connectionState) {
      RealmConnectionState.checking => context.colors.info,
      RealmConnectionState.offline => context.colors.offline,
      RealmConnectionState.unavailable => context.colors.danger,
      RealmConnectionState.notSelected ||
      RealmConnectionState.online => context.colors.online,
    };
    return Icon(Icons.cloud_off_rounded, size: 42, color: color);
  }
}
