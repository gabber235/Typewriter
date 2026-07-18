import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ion.dart";
import "package:iconify_flutter_plus/icons/lucide.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/app/presentation/shortcuts/shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/current_interaction_mode.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/modes/normal_mode.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/modes/timeline_modes.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_controller.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_layout.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_placement.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_viewport.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline_style.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/selector.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/utilities/adaptive_single_activator.dart";
import "package:typewriter_panel/shared/utilities/shortcut.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

List<ActionShortcut> buildTimelineShortcuts({
  required bool canCommit,
  required Object currentInteractionMode,
  required TimelineController controller,
  required TimelineStyle style,
  required TimelineViewport viewport,
  required TimelineLayoutResult layout,
  required TimelinePlacementResult placement,
  required GlobalKey planeGlobalKey,
  required List<MoveTimelinePreview> Function(TimelineIdentifier id)
  resolveMovePreviews,
  required List<TimelinePreview> Function(
    TimelineIdentifier id,
    TimelineInteractionMode mode,
  )
  resolveResizePreviews,
  required ValueNotifier<double> totalDelta,
}) {
  return [
    if (canCommit && currentInteractionMode is! TimelineMoveMode)
      ActionShortcut(
        id: "timeline_move_mode_activate",
        label: "Move Mode",
        description: "Go to Move Mode",
        activators: [SingleActivator(shift: true, LogicalKeyboardKey.keyM)],
        icon: Icones(Ion.md_move),
        onInvoke: (ref) => _invokeTimelineMoveModeActivate(
          ref: ref,
          controller: controller,
          placement: placement,
          viewport: viewport,
          resolveMovePreviews: resolveMovePreviews,
          totalDelta: totalDelta,
        ),
        priority: 10,
      ),
    if (canCommit &&
        (currentInteractionMode is! TimelineResizeMode ||
            currentInteractionMode.mode == TimelineInteractionMode.resizeStart))
      ActionShortcut(
        id: "timeline_resize_start_mode_activate",
        label: "Resize Start Mode",
        description: "Resize the selected segments start",
        activators: [SingleActivator(shift: true, LogicalKeyboardKey.keyS)],
        icon: Icones(Lucide.move_diagonal_2),
        onInvoke: (ref) => _invokeTimelineResizeStartModeActivate(
          ref: ref,
          controller: controller,
          placement: placement,
          viewport: viewport,
          resolveResizePreviews: resolveResizePreviews,
          totalDelta: totalDelta,
        ),
        priority: 10,
      ),
    if (canCommit &&
        (currentInteractionMode is! TimelineResizeMode ||
            currentInteractionMode.mode == TimelineInteractionMode.resizeEnd))
      ActionShortcut(
        id: "timeline_resize_end_mode_activate",
        label: "Resize End Mode",
        description: "Resize the selected segments end",
        activators: [SingleActivator(shift: true, LogicalKeyboardKey.keyE)],
        icon: Icones(Lucide.move_diagonal_2),
        onInvoke: (ref) => _invokeTimelineResizeEndModeActivate(
          ref: ref,
          controller: controller,
          placement: placement,
          viewport: viewport,
          resolveResizePreviews: resolveResizePreviews,
          totalDelta: totalDelta,
        ),
        priority: 10,
      ),
    ActionShortcut(
      id: "timeline_zoom_in",
      label: "Zoom In",
      description: "Zoom the timeline in",
      activators: [
        for (final key in [
          LogicalKeyboardKey.equal,
          LogicalKeyboardKey.add,
          LogicalKeyboardKey.numpadEqual,
          LogicalKeyboardKey.numpadAdd,
        ]) ...[
          SingleActivator(key),
          SingleActivator(key, shift: true),
          AdaptiveSingleActivator(key, control: true),
          AdaptiveSingleActivator(key, control: true, shift: true),
        ],
        for (final ch in ["=", "+"]) ...[
          CharacterActivator(ch),
          CharacterActivator(ch, meta: true),
          CharacterActivator(ch, control: true),
        ],
      ],
      priority: -2,
      onInvoke: (_) => _invokeTimelineZoomIn(
        planeGlobalKey: planeGlobalKey,
        controller: controller,
        style: style,
      ),
    ),
    ActionShortcut(
      id: "timeline_zoom_out",
      label: "Zoom Out",
      description: "Zoom the timeline out",
      activators: [
        for (final key in [
          LogicalKeyboardKey.minus,
          LogicalKeyboardKey.underscore,
          LogicalKeyboardKey.numpadSubtract,
        ]) ...[
          SingleActivator(key),
          SingleActivator(key, shift: true),
          AdaptiveSingleActivator(key, control: true),
          AdaptiveSingleActivator(key, control: true, shift: true),
        ],
        for (final ch in ["-", "_"]) ...[
          CharacterActivator(ch),
          CharacterActivator(ch, meta: true),
          CharacterActivator(ch, control: true),
        ],
      ],
      priority: -2,
      onInvoke: (_) => _invokeTimelineZoomOut(
        planeGlobalKey: planeGlobalKey,
        controller: controller,
        style: style,
      ),
    ),
    ActionShortcut(
      id: "timeline_zoom_reset",
      label: "Reset Zoom",
      description: "Reset zoom to 100% and center",
      activators: [
        for (final key in [
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.numpad0,
        ]) ...[
          SingleActivator(key),
          AdaptiveSingleActivator(key, control: true),
        ],
      ],
      priority: -2,
      onInvoke: (_) => _invokeTimelineZoomReset(
        controller: controller,
        viewport: viewport,
        layout: layout,
      ),
    ),

    if (currentInteractionMode is NormalMode) ...[
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "timeline_plane_move_${key.debugName?.snakeCase}",
            label: "Move Plane ${direction.name.titleCase()}",
            description: "Move timeline plane ${direction.name.toLowerCase()}",
            activators: [
              SingleActivator(key, alt: true),
              SingleActivator(key, alt: true, shift: true),
            ],
            priority: 1,
            show: false,
            onInvoke: (ref) => _invokeTimelinePlaneMove(direction, controller),
          ),

      ActionShortcut(
        id: "timeline_plane_move",
        label: "Move Plane",
        description: "Move the timeline plane",
        activators: [
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowRight,
          ]),
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.keyH,
            LogicalKeyboardKey.keyJ,
            LogicalKeyboardKey.keyK,
            LogicalKeyboardKey.keyL,
          ]),
        ],
        priority: 1,
      ),
    ],
  ];
}

TimelineIdentifier? _focusedTimelineId() {
  final primaryFocusedId = SelectableScope.primaryFocusedId();
  if (primaryFocusedId == null) return null;
  return TimelineIdentifier(primaryFocusedId.id);
}

Object? _invokeTimelineMoveModeActivate({
  required WidgetRef ref,
  required TimelineController controller,
  required TimelinePlacementResult placement,
  required TimelineViewport viewport,
  required List<MoveTimelinePreview> Function(TimelineIdentifier id)
  resolveMovePreviews,
  required ValueNotifier<double> totalDelta,
}) {
  final identifier = _focusedTimelineId();
  if (identifier == null) return null;

  ref.read(currentInteractionModeProvider.notifier).setMode(TimelineMoveMode());
  controller.startInteractionSession(previews: resolveMovePreviews(identifier));
  totalDelta.value = 0;

  final element = placement.placementById[identifier];
  if (element != null) {
    controller.centerOn(viewport, element);
  }
  return null;
}

Object? _invokeTimelineResizeStartModeActivate({
  required WidgetRef ref,
  required TimelineController controller,
  required TimelinePlacementResult placement,
  required TimelineViewport viewport,
  required List<TimelinePreview> Function(
    TimelineIdentifier id,
    TimelineInteractionMode mode,
  )
  resolveResizePreviews,
  required ValueNotifier<double> totalDelta,
}) {
  final identifier = _focusedTimelineId();
  if (identifier == null) return null;

  ref
      .read(currentInteractionModeProvider.notifier)
      .setMode(TimelineResizeMode(mode: TimelineInteractionMode.resizeStart));
  controller.startInteractionSession(
    previews: resolveResizePreviews(
      identifier,
      TimelineInteractionMode.resizeStart,
    ),
  );
  totalDelta.value = 0;

  final element = placement.placementById[identifier];
  if (element != null) {
    controller.centerOn(viewport, element);
  }
  return null;
}

Object? _invokeTimelineResizeEndModeActivate({
  required WidgetRef ref,
  required TimelineController controller,
  required TimelinePlacementResult placement,
  required TimelineViewport viewport,
  required List<TimelinePreview> Function(
    TimelineIdentifier id,
    TimelineInteractionMode mode,
  )
  resolveResizePreviews,
  required ValueNotifier<double> totalDelta,
}) {
  final identifier = _focusedTimelineId();
  if (identifier == null) return null;

  ref
      .read(currentInteractionModeProvider.notifier)
      .setMode(TimelineResizeMode(mode: TimelineInteractionMode.resizeEnd));
  controller.startInteractionSession(
    previews: resolveResizePreviews(
      identifier,
      TimelineInteractionMode.resizeEnd,
    ),
  );
  totalDelta.value = 0;

  final element = placement.placementById[identifier];
  if (element != null) {
    controller.centerOn(viewport, element);
  }
  return null;
}

Object? _invokeTimelineZoomIn({
  required GlobalKey planeGlobalKey,
  required TimelineController controller,
  required TimelineStyle style,
}) {
  final planeBox =
      planeGlobalKey.currentContext?.findRenderObject() as RenderBox?;
  if (planeBox == null) return null;
  final focal = planeBox.size.center(Offset.zero);
  final scaleDelta = math.exp(25 * 0.0025);
  controller.zoomAt(
    localDx: focal.dx,
    scaleDelta: scaleDelta,
    minPixelsPerFrame: style.minPixelsPerFrame,
    maxPixelsPerFrame: style.maxPixelsPerFrame,
  );
  return null;
}

Object? _invokeTimelineZoomOut({
  required GlobalKey planeGlobalKey,
  required TimelineController controller,
  required TimelineStyle style,
}) {
  final planeBox =
      planeGlobalKey.currentContext?.findRenderObject() as RenderBox?;
  if (planeBox == null) return null;
  final focal = planeBox.size.center(Offset.zero);
  final scaleDelta = math.exp(-25 * 0.0025);
  controller.zoomAt(
    localDx: focal.dx,
    scaleDelta: scaleDelta,
    minPixelsPerFrame: style.minPixelsPerFrame,
    maxPixelsPerFrame: style.maxPixelsPerFrame,
  );
  return null;
}

void _invokeTimelineZoomReset({
  required TimelineController controller,
  required TimelineViewport viewport,
  required TimelineLayoutResult layout,
}) {
  controller.resetZoom(viewport, layout);
}

void _invokeTimelinePlaneMove(
  TraversalDirection direction,
  TimelineController controller,
) {
  final (dx, dy) = switch (direction) {
    TraversalDirection.up => (0, -1),
    TraversalDirection.down => (0, 1),
    TraversalDirection.left => (-1, 0),
    TraversalDirection.right => (1, 0),
  };

  int framesJump() {
    if (HardwareKeyboard.instance.isShiftPressed) return 100;
    return 10;
  }

  final factor = controller.pixelsPerFrame * framesJump();

  final fullDx = dx * factor;
  final fullDy = dy * factor;

  controller.panBy(dx: fullDx, dy: fullDy);
}
