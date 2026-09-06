part of "../../content_renderer.dart";

extension StatusElementRendering on StatusElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final resolved = _resolveStatus(scope);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final status = resolved.valueOrNull!;
    final visual = status.tone._visual(context);

    return Semantics(
      label: status.label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, size: 14, color: visual.color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: DefaultTextStyle.of(
                context,
              ).style.copyWith(color: visual.color),
            ),
          ],
        ),
      ),
    );
  }

  TypeResult<_ResolvedStatus> _resolveStatus(PresentationRenderScope scope) {
    final result = scope.evaluate(value);
    if (result case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final source = result.valueOrNull!;
    StatusAppearance? appearance;
    for (final candidate in cases) {
      if (candidate.match == source) {
        appearance = candidate.appearance;
        break;
      }
    }
    appearance ??= fallback ?? const StatusAppearance(tone: StatusTone.unknown);
    if (appearance.label == null) {
      return TypeResult.success(
        _ResolvedStatus(
          tone: appearance.tone,
          label: source.expressionDisplayText,
        ),
      );
    }
    final label = scope.evaluate(appearance.label!);
    if (label case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    if (label.valueOrNull case StringValue(:final value)) {
      return TypeResult.success(
        _ResolvedStatus(tone: appearance.tone, label: value),
      );
    }
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Status label must evaluate to a string",
      ),
    ]);
  }
}

extension on StatusTone {
  _StatusVisual _visual(BuildContext context) => switch (this) {
    StatusTone.neutral => _StatusVisual(
      context.colors.contentSecondary,
      Icons.circle_outlined,
    ),
    StatusTone.unknown => _StatusVisual(
      context.colors.contentSecondary,
      Icons.help_outline,
    ),
    StatusTone.information => _StatusVisual(
      context.colors.info,
      Icons.info_outline,
    ),
    StatusTone.success => _StatusVisual(
      context.colors.success,
      Icons.check_circle_outline,
    ),
    StatusTone.warning => _StatusVisual(
      context.colors.warning,
      Icons.warning_amber_rounded,
    ),
    StatusTone.danger => _StatusVisual(
      context.colors.danger,
      Icons.error_outline,
    ),
    StatusTone.active => _StatusVisual(
      context.colors.online,
      Icons.play_circle_outline,
    ),
    StatusTone.inactive => _StatusVisual(
      context.colors.offline,
      Icons.stop_circle_outlined,
    ),
    StatusTone.online => _StatusVisual(
      context.colors.online,
      Icons.cloud_done_outlined,
    ),
    StatusTone.offline => _StatusVisual(
      context.colors.offline,
      Icons.cloud_off_outlined,
    ),
    StatusTone.pending => _StatusVisual(
      context.colors.info,
      Icons.schedule_outlined,
    ),
    StatusTone.inProgress => _StatusVisual(context.colors.info, Icons.sync),
    StatusTone.paused => _StatusVisual(
      context.colors.warning,
      Icons.pause_circle_outline,
    ),
  };
}

class _ResolvedStatus {
  const _ResolvedStatus({required this.tone, required this.label});

  final StatusTone tone;
  final String label;
}

class _StatusVisual {
  const _StatusVisual(this.color, this.icon);

  final Color color;
  final IconData icon;
}
