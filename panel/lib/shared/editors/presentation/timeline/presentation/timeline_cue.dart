import "package:typewriter_panel/typewriter_panel.dart";

/// A labelled timeline element its user can drag to new frames, select and
/// open.
///
/// Segments get [TimelineSegmentSurface], so dragging the body moves them and
/// dragging an edge resizes them; keyframes get [TimelineKeyframeSurface].
/// With a [selectableId] the cue is a [Selector]: a tap selects and focuses
/// it, which lets the timeline's keyboard move and resize modes act on it,
/// and a double tap opens it. Without one, a tap opens it. The cue reads as
/// [label] to assistive technology. Committing the frames stays with the
/// timeline's caller.
///
/// While a timeline move or resize mode is active, the arrow keys on a
/// focused cue drive that mode instead of the cue's closed context menu,
/// which would otherwise take them for focus traversal.
class TimelineCue extends HookConsumerWidget {
  const TimelineCue({
    required this.data,
    required this.label,
    this.selectableId,
    this.onOpen,
    super.key,
  });

  final TimelineElementBuildData data;

  /// The name the user reads on the cue.
  final String label;

  /// What selecting the cue selects; its id must be the element's
  /// [TimelineIdentifier] id. Null leaves the cue unselectable.
  final SelectableIdentifier? selectableId;

  /// Opens what the cue stands for; null when the cue opens nothing.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    final id = selectableId;
    if (id == null) {
      return GestureDetector(onTap: onOpen, child: _cue(context, false));
    }
    final mode = ref.watch(currentInteractionModeProvider);
    final directionalMode =
        mode is TimelineMoveMode || mode is TimelineResizeMode
        ? mode as DirectionalInteractionMode
        : null;
    return Selector(
      selectableId: id,
      focusNode: focus,
      shortcuts: {
        if (directionalMode != null)
          for (final entry in movementShortcuts.entries)
            for (final key in entry.key)
              SingleActivator(key): directionalMode.intentForDirection(
                entry.value,
              ),
      },
      onDoubleTap: onOpen,
      builder: (selected, focused, _) => _cue(context, selected || focused),
    );
  }

  // ignore: avoid_positional_boolean_parameters
  Widget _cue(BuildContext context, bool highlighted) {
    final color = data.element.color;
    final strong = data.isPrimaryPreview || highlighted;
    final outlineColor = strong
        ? color
        : color.withValues(alpha: data.isPreview ? 0.7 : 0.4);
    final outlineWidth = strong ? 2.0 : 1.0;
    final surface = switch (data.element) {
      TimelineSegment() => TimelineSegmentSurface(
        data: data,
        fillColor: color.withValues(alpha: 0.2),
        outlineColor: outlineColor,
        outlineWidth: outlineWidth,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
      TimelineKeyframe() => TimelineKeyframeSurface(
        data: data,
        fillColor: color,
        outlineColor: outlineColor,
        outlineWidth: outlineWidth,
        child: const SizedBox.expand(),
      ),
    };
    // The cue reads as its label alone whatever its surface draws inside;
    // the plane gives every element its own node, so the label merges into
    // the cue's focus node when it is selectable.
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: surface),
    );
  }
}
