import "dart:math";

import "package:collection/collection.dart";
import "package:collection_ext/all.dart";
import "package:flutter/material.dart" hide FilledButton, Title;
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/hooks/global_key.dart";
import "package:typewriter/hooks/text_size.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/models/segment.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/color_converter.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/fonts.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/popups.dart";
import "package:typewriter/widgets/components/app/empty_screen.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/decorated_text_field.dart";
import "package:typewriter/widgets/components/general/filled_button.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/components/general/toasts.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/object.dart";
import "package:typewriter/widgets/inspector/heading.dart";
import "package:typewriter/widgets/inspector/inspector.dart";
import "package:typewriter/widgets/inspector/section_title.dart";

part "cinematic_view.freezed.dart";
part "cinematic_view.g.dart";

const colorConverter = NullableColorConverter();

const _minimalFractionSize = 30.0;

const _minThumbSpacing = 10 * 2 + 20;

//</editor-fold>

//<editor-fold desc="Track Background & Numbers">
const _possibleFractions = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];

final inspectingSegmentIdProvider =
    StateNotifierProvider<InspectingSegmentIdNotifier, String?>(
  InspectingSegmentIdNotifier.new,
  name: "inspectingSegmentIdProvider",
);

final _moveNotifierProvider = StateNotifierProvider<_MoveNotifier, _MoveState?>(
  _MoveNotifier.new,
  name: "_moveNotifierProvider",
);

final _trackStateProvider =
    StateNotifierProvider.autoDispose<_TrackStateProvider, _TrackState>(
  _TrackStateProvider.new,
  name: "_trackStateProvider",
);

void deleteSegmentConfirmation(
  BuildContext context,
  PassingRef ref,
  String entryId,
  String segmentId,
) {
  showConfirmationDialogue(
    context: context,
    title: "Delete Segment",
    content: "Are you sure you want to delete this segment?",
    confirmText: "Delete",
    onConfirm: () {
      _deleteSegment(ref, entryId, segmentId);
    },
  );
}

@riverpod
Segment? inspectingSegment(Ref ref) {
  final segmentId = ref.watch(inspectingSegmentIdProvider);
  if (segmentId == null) return null;

  final entryId = ref.watch(inspectingEntryIdProvider);
  if (entryId == null) return null;

  final segments = ref.watch(_segmentsProvider(entryId, segmentId));
  return segments.firstOrNull;
}

String? _addSegment(
  PassingRef ref,
  String entryId,
  String segmentPath, [
  Map<String, dynamic> data = const {},
]) {
  final segments = ref.read(_segmentsProvider(entryId, segmentPath));
  final page = ref.read(currentPageProvider);
  if (page == null) return null;
  final entry = ref.read(entryProvider(page.id, entryId));
  if (entry == null) return null;

  final blueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
  if (blueprint == null) return null;
  final segmentField = blueprint.getField(segmentPath);
  if (segmentField == null) return null;

  final minFrames = segmentField.get<int>("min");
  final maxFrames = segmentField.get<int>("max");

  final minSpace = minFrames ?? min(maxFrames ?? 10, 10);

  final timings = _findSegmentSpace(
    ref,
    segments,
    minSpace,
    maxFrames,
  );

  if (timings == null) {
    Toasts.showError(
      ref,
      "Could not add segment",
      description: "There is not enough space to add a segment.",
    );
    return null;
  }

  final (:startFrame, :endFrame) = timings;

  final segment = segmentField.defaultValue();
  if (segment == null) return null;

  final newSegment = {
    ...segment,
    ...data,
    "startFrame": startFrame,
    "endFrame": endFrame,
  };

  final listPath = segmentPath.replaceSuffix(".*", "");
  final list = entry.get(listPath) as List? ?? [];
  final newList = [...list, newSegment];

  page.updateEntryValue(ref, entry, listPath, newList);

  return "$listPath.${newList.length - 1}";
}

@riverpod
List<Segment> _allSegments(Ref ref, String entryId) {
  final paths = ref.watch(_segmentPathsProvider(entryId));
  return paths.keys
      .map((path) => ref.watch(_segmentsProvider(entryId, path)))
      .nonNulls
      .expand((x) => x)
      .toList();
}

@riverpod
List<String> _cinematicEntryIds(Ref ref) {
  final page = ref.watch(currentPageProvider);
  if (page == null) return [];

  return page.entries.map((entry) => entry.id).toList();
}

void _deleteSegment(PassingRef ref, String entryId, String segmentPath) {
  final page = ref.read(currentPageProvider);
  if (page == null) {
    Toasts.showError(
      ref,
      "Could not delete segment",
      description: "No page is selected.",
    );
    return;
  }
  final entry = ref.read(entryProvider(page.id, entryId));
  if (entry == null) {
    Toasts.showError(
      ref,
      "Could not delete segment",
      description: "No entry is selected.",
    );
    return;
  }

  final blueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
  if (blueprint == null) {
    Toasts.showError(
      ref,
      "Could not delete segment",
      description: "No blueprint is found for the selected entry.",
    );
    return;
  }
  final segmentBlueprint = blueprint.getField(segmentPath);
  if (segmentBlueprint == null) {
    Toasts.showError(
      ref,
      "Could not delete segment",
      description: "No blueprint is found for the selected segment.",
    );
    return;
  }

  final parts = segmentPath.split(".");
  final listPath = parts.sublist(0, parts.length - 1).join(".");
  final list = entry.get(listPath) as List? ?? [];

  final index = int.tryParse(parts.last) ?? 0;
  final newList = [...list]..removeAt(index);

  page.updateEntryValue(ref, entry, listPath, newList);
}

void _duplicateSelectedSegment(PassingRef ref) {
  final entryId = ref.read(inspectingEntryIdProvider);
  if (entryId == null) return;
  final segment = ref.read(inspectingSegmentProvider);
  if (segment == null) return;

  final segmentId = _addSegment(ref, entryId, segment.path, segment.data);
  if (segmentId == null) return;
  ref.read(inspectingSegmentIdProvider.notifier).select(entryId, segmentId);
}

@riverpod
int _endingFrame(Ref ref, String entryId) {
  final segments = ref.watch(_allSegmentsProvider(entryId));
  return segments.map((segment) => segment.endFrame).maxOrNull ?? 0;
}

@riverpod
List<ContextMenuTile> _entryContextActions(
  Ref ref,
  String entryId,
) {
  final paths = ref.watch(_segmentPathsProvider(entryId));

  return paths.entries.map((e) {
    final path = e.key;
    final modifier = e.value;

    final title = path
            .replaceSuffix(".*", "")
            .split(".")
            .lastOrNull
            ?.singular
            .titleCase() ??
        path;

    final modifierData = modifier.data;

    final hexColor = modifierData["color"] as String? ?? "#009688";
    final color = colorConverter.fromJson(hexColor) ?? Colors.teal;

    final icon = modifierData["icon"] as String? ?? TWIcons.plus;

    return ContextMenuTile.button(
      title: "Add $title",
      onTap: () {
        _addSegment(ref.passing, entryId, path);
      },
      icon: icon,
      color: color,
    );
  }).toList();
}

({int startFrame, int endFrame})? _findSegmentSpace(
  PassingRef ref,
  List<Segment> segments,
  int minSize,
  int? maxSize,
) {
  final lastFrame = ref.read(_trackStateProvider).totalFrames;
  var endFrame = lastFrame;

  while (endFrame > 0) {
    final segment = _includesSegment(endFrame - minSize, endFrame, segments);

    if (segment != null) {
      // If a segment is found, move to the start of that segment
      endFrame = segment.startFrame - 1;
      continue;
    }

    // If no segment is found, we have found a gap. Check if it is long enough
    final startFrame = segments
            .map((e) => e.endFrame)
            .where((frame) => frame <= endFrame - minSize)
            .maxOrNull ??
        0;
    if (endFrame - startFrame >= minSize) {
      break;
    }
    // If the gap is not long enough, move to the next segment
    endFrame = (segments
                .map((e) => e.startFrame)
                .where((frame) => frame < startFrame)
                .maxOrNull ??
            1) -
        1;
  }

  final startFrame = segments
          .map((e) => e.endFrame)
          .where((frame) => frame <= endFrame - minSize)
          .maxOrNull ??
      0;

  if (maxSize != null) {
    endFrame = min(endFrame, startFrame + maxSize);
  }

  if (endFrame - startFrame < minSize) return null;
  return (startFrame: startFrame, endFrame: endFrame);
}

@riverpod
double _frameEndOffset(Ref ref, int frame) {
  final trackSize = ref.watch(_trackSizeProvider);
  final frameSpacing = ref.watch(_frameSpacingProvider);
  return trackSize - frame * frameSpacing;
}

@riverpod
double _frameSpacing(Ref ref) {
  final trackState = ref.watch(_trackStateProvider);
  final totalFrames = trackState.totalFrames;
  final width = trackState.width - 16;

  if (totalFrames == 0) return 0;
  if (width <= 0) return 0;

  final lookingAt = max(1, trackState.endFrame - trackState.startFrame);
  final spacing = width / lookingAt;
  return spacing;
}

@riverpod
double _frameStartOffset(Ref ref, int frame) {
  final frameSpacing = ref.watch(_frameSpacingProvider);
  return frame * frameSpacing;
}

@riverpod
List<String> _ignoreEntryFields(Ref ref) {
  final entryId = ref.watch(inspectingEntryIdProvider);
  if (entryId == null) return [];

  final entries = ref.watch(_segmentPathsProvider(entryId));
  final paths = entries.keys.toList();

  return paths.map((e) => e.replaceSuffix(".*", "")).toList();
}

/// Finds a segment that overlaps the given range
/// If no segment is found, returns null
Segment? _includesSegment(
  int startFrame,
  int endFrame,
  List<Segment> segments,
) {
  return segments
      .firstWhereOrNull((segment) => segment.overlaps(startFrame, endFrame));
}

//</editor-fold>

//<editor-fold desc="Entry Display Prefix">
@riverpod
String _longestEntryName(Ref ref) {
  final entryIds = ref.watch(_cinematicEntryIdsProvider);
  final names = entryIds
          .map((entryId) => ref.watch(entryNameProvider(entryId)))
          .nonNulls
          .toList() +
      ["Track Duration"];
  return names.isEmpty
      ? ""
      : names.reduce((a, b) => a.length > b.length ? a : b);
}

@riverpod
ObjectBlueprint? _segmentFields(Ref ref) {
  final blueprint = ref.watch(
    inspectingEntryDefinitionProvider
        .select((definition) => definition?.blueprint),
  );
  if (blueprint == null) return null;
  final segmentId = ref.watch(inspectingSegmentIdProvider);
  if (segmentId == null) return null;
  final dataBlueprint = blueprint.getField(segmentId);
  if (dataBlueprint is! ObjectBlueprint) return null;
  return dataBlueprint;
}

//<editor-fold desc="Entry & Track & Segment States">
@riverpod
Map<String, Modifier> _segmentPaths(Ref ref, String entryId) {
  final blueprintId = ref.watch(entryBlueprintIdProvider(entryId));
  if (blueprintId == null) return {};
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return {};

  return blueprint.fieldsWithModifier("segment");
}

@riverpod
List<Segment> _segments(Ref ref, String entryId, String path) {
  final paths = ref.watch(_segmentPathsProvider(entryId));
  final modifier = paths.findModifier(path);
  if (modifier == null) return [];

  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return [];

  final blueprint = ref.watch(entryBlueprintProvider(entry.blueprintId));
  if (blueprint == null) return [];

  final segmentModifierData = modifier.data;

  final hexColor = segmentModifierData["color"] as String? ?? "#000000";
  final color = colorConverter.fromJson(hexColor) ?? Colors.teal;

  final icon = segmentModifierData["icon"] as String? ?? TWIcons.star;

  final field = blueprint.getField(path.wild());
  final min = field?.get("min") as int?;
  final max = field?.get("max") as int?;

  return entry.getAll(path).mapIndexed((index, segment) {
    final startFrame = segment["startFrame"] as int? ?? 0;
    final endFrame = segment["endFrame"] as int? ?? 0;

    final data = stringMap(segment);

    return Segment(
      path: path.wild(),
      index: index,
      color: color,
      icon: icon,
      startFrame: startFrame,
      endFrame: startFrame > endFrame ? startFrame : endFrame,
      minFrames: min,
      maxFrames: max,
      data: data,
    );
  }).toList();
}

@riverpod
bool _showThumbs(Ref ref, int startFrame, int endFrame) {
  if (startFrame == endFrame) return false;
  final startOffset = ref.watch(_frameStartOffsetProvider(startFrame));
  // We want to use the start offset provider here as we want the offset from the start of the track to the end of the frame.
  final endOffset = ref.watch(_frameStartOffsetProvider(endFrame));

  return endOffset - startOffset > _minThumbSpacing;
}

@riverpod
double _sliderEndOffset(Ref ref) {
  final end = ref.watch(_trackStateProvider.select((state) => state.end));
  final width = ref.watch(_trackStateProvider.select((state) => state.width));
  return (1 - end) * width;
}

@riverpod
double _sliderStartOffset(Ref ref) {
  final start = ref.watch(_trackStateProvider.select((state) => state.start));
  final width = ref.watch(_trackStateProvider.select((state) => state.width));
  return start * width;
}

@riverpod
List<int> _timeFractionFrames(
  Ref ref, {
  double fractionModifier = 1.0,
}) {
  final startFrame =
      ref.watch(_trackStateProvider.select((state) => state.startFrame));
  final endFrame =
      ref.watch(_trackStateProvider.select((state) => state.endFrame));
  final fractions =
      (ref.watch(_timeFractionsProvider) * fractionModifier).ceil();

  final firstFractionFrame = (startFrame / fractions).ceil() * fractions;
  return firstFractionFrame.upTo(endFrame, step: fractions).toList();
}

@riverpod
int _timeFractions(Ref ref) {
  final duration =
      ref.watch(_trackStateProvider.select((state) => state.duration));
  final width = ref.watch(_trackStateProvider.select((state) => state.width));
  return _possibleFractions.firstWhereOrNull(
        (fraction) => (_minimalFractionSize * duration) / fraction < width,
      ) ??
      1000;
}

@riverpod
double _timePointOffset(
  Ref ref,
  int frame,
  double widgetWidth,
) {
  final startFrame =
      ref.watch(_trackStateProvider.select((state) => state.startFrame));
  final frameSpacing = ref.watch(_frameSpacingProvider);

  if (frame < startFrame) return 0.0;

  return (frame - startFrame) * frameSpacing - widgetWidth / 2;
}

@riverpod
int _totalSequenceFrames(Ref ref) {
  final entryIds = ref.watch(_cinematicEntryIdsProvider);
  final frames = entryIds
      .map((entryId) => ref.watch(_endingFrameProvider(entryId)))
      .nonNulls
      .toList();
  return frames.map((frame) => frame).maxOrNull ?? 0;
}

@riverpod
double _trackBackgroundFractionModifier(
  Ref ref,
) {
  final fractions = ref.watch(_timeFractionsProvider);
  if (fractions == 1) return 1.0;
  if (fractions == 5) return 1.0;
  return 1 / 2;
}

@riverpod
List<_FrameLine> _trackBackgroundLines(Ref ref) {
  final fractions = ref.watch(_timeFractionsProvider);
  final fractionModifier = ref.watch(_trackBackgroundFractionModifierProvider);
  final fractionFrames = ref
      .watch(_timeFractionFramesProvider(fractionModifier: fractionModifier));

  final frameSpacing = ref.watch(_frameSpacingProvider);
  final startFrame =
      ref.watch(_trackStateProvider.select((state) => state.startFrame));

  final lines = <_FrameLine>[];
  for (final frame in fractionFrames) {
    final offset =
        frame < startFrame ? 0.0 : (frame - startFrame) * frameSpacing - 1 / 2;

    lines.add(
      _FrameLine(frame: frame, offset: offset, primary: frame % fractions == 0),
    );
  }
  return lines;
}

@riverpod
double _trackOffset(Ref ref) {
  final trackState = ref.watch(_trackStateProvider);
  final totalFrames = trackState.totalFrames;

  if (totalFrames == 0) return 0;

  final spacing = ref.watch(_frameSpacingProvider);
  final offset = trackState.startFrame * spacing;
  return offset;
}

@riverpod
double _trackSize(Ref ref) {
  final totalFrames =
      ref.watch(_trackStateProvider.select((state) => state.totalFrames));
  final spacing = ref.watch(_frameSpacingProvider);

  if (totalFrames == 0) return 0;

  return totalFrames * spacing + 16;
}

class CinematicInspector extends HookConsumerWidget {
  const CinematicInspector({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectingEntry = ref.watch(inspectingEntryProvider);
    final inspectingSegment = ref.watch(inspectingSegmentProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: inspectingSegment != null
            ? _SegmentInspector(key: ValueKey(inspectingSegment.truePath))
            : inspectingEntry != null
                ? EntryInspector(
                    key: ValueKey(inspectingEntry.id),
                    actions: ref.watch(
                      _entryContextActionsProvider(inspectingEntry.id),
                    ),
                    ignoreFields: ref.watch(_ignoreEntryFieldsProvider),
                    sections: const [
                      _SegmentSelector(),
                    ],
                  )
                : const EmptyInspector(),
      ),
    );
  }
}

class CinematicView extends HookConsumerWidget {
  const CinematicView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryIds = ref.watch(_cinematicEntryIdsProvider);

    if (entryIds.isEmpty) {
      return EmptyScreen(
        title: "There are no cinematic entries on this page.",
        buttonText: "Add Entry",
        onButtonPressed: () => ref.read(searchProvider.notifier).asBuilder()
          ..fetchNewEntry()
          ..nonGenericAddEntry()
          ..tag("cinematic", canRemove: false)
          ..open(),
      );
    }

    return ReorderableListView.builder(
      itemCount: entryIds.length,
      buildDefaultDragHandles: false,
      proxyDecorator: _proxyDecorator,
      header: const _Heading(),
      itemBuilder: (context, index) {
        final entryId = entryIds[index];
        return _EntryRow(index: index, entryId: entryId, key: Key(entryId));
      },
      onReorder: (oldIndex, newIndex) {
        final page = ref.read(currentPageProvider);
        if (page == null) return;
        page.reorderEntry(ref.passing, entryIds[oldIndex], newIndex);
      },
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }
}

//</editor-fold>

//<editor-fold desc="Inspector">
class InspectingSegmentIdNotifier extends StateNotifier<String?> {
  InspectingSegmentIdNotifier(this.ref) : super(null);

  final Ref ref;

  void clear() {
    ref.read(currentEditingFieldProvider.notifier).clearIfSame(state ?? "");
    state = null;
  }

  void select(String entryId, String segmentPath) {
    ref
        .read(inspectingEntryIdProvider.notifier)
        .selectEntry(entryId, unSelectSegment: false);
    state = segmentPath;
    ref.read(currentEditingFieldProvider.notifier).path = segmentPath;
  }
}

class _BackgroundLinePainter extends CustomPainter {
  const _BackgroundLinePainter({
    required this.lines,
  });
  final List<_FrameLine> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final primaryPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1;

    final secondaryPaint = Paint()
      ..color = Colors.grey.shade700.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (final line in lines) {
      final offset = line.offset;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        line.primary ? primaryPaint : secondaryPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundLinePainter oldDelegate) {
    return oldDelegate.lines != lines;
  }
}

class _DeleteSegment extends HookConsumerWidget {
  const _DeleteSegment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        final segmentId = ref.read(inspectingSegmentIdProvider);
        if (segmentId == null) return;
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId == null) return;

        deleteSegmentConfirmation(context, ref.passing, entryId, segmentId);
      },
      icon: const Iconify(TWIcons.trash),
      label: const Text("Delete Segment"),
      color: Theme.of(context).colorScheme.error,
    );
  }
}

class _DuplicateSegment extends HookConsumerWidget {
  const _DuplicateSegment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        ref.watch(inspectingSegmentProvider.select((s) => s?.color)) ??
            Theme.of(context).colorScheme.primary;
    return FilledButton.icon(
      onPressed: () => _duplicateSelectedSegment(ref.passing),
      icon: const Iconify(TWIcons.duplicate),
      label: const Text("Duplicate Segment"),
      color: color,
    );
  }
}

class _DurationField extends HookConsumerWidget {
  const _DurationField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    final totalFrames =
        ref.watch(_trackStateProvider.select((state) => state.totalFrames));

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DecoratedTextField(
          focus: focus,
          text: totalFrames.toString(),
          maxLines: 1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            hintText: "Duration",
            hintStyle: TextStyle(fontSize: 13),
          ),
          onChanged: (value) {
            final frames = int.tryParse(value);
            if (frames == null) return;
            ref.read(_trackStateProvider.notifier).changeTotalFrames(frames);
          },
        ),
      ),
    );
  }
}

class _EndFrameField extends HookConsumerWidget {
  const _EndFrameField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentId = ref.watch(inspectingSegmentIdProvider);

    if (segmentId == null) return const SizedBox.shrink();

    return _FrameField(
      title: "End Frame",
      path: "$segmentId.endFrame",
      icon: TWIcons.stepBackward,
      hintText: "Enter a frame number",
      onValidate: (frame) {
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId == null) return "No entry selected";
        final segment = ref.read(inspectingSegmentProvider);
        if (segment == null) return "No segment selected";

        if (frame < segment.startFrame) return "Cannot be before start frame";

        if (segment.minFrames != null &&
            frame - segment.startFrame < segment.minFrames!) {
          return "The segment must be at least ${segment.minFrames} frames long";
        }

        if (segment.maxFrames != null &&
            frame - segment.startFrame > segment.maxFrames!) {
          return "The segment must be at most ${segment.maxFrames} frames long";
        }

        final segments = ref.read(_segmentsProvider(entryId, segmentId.wild()));
        final nextSegment = segments
            .where((s) => s.startFrame >= segment.endFrame)
            .minBy((_, s) => s.startFrame);
        final maximumFrame = nextSegment?.startFrame;
        if (maximumFrame == null &&
            frame > ref.read(_trackStateProvider).totalFrames) {
          return "Cannot extend past the end of the track";
        }
        if (maximumFrame != null && frame > maximumFrame) {
          return "Cannot overlap with next segment";
        }
        return null;
      },
    );
  }
}

class _EntryRow extends HookConsumerWidget {
  const _EntryRow({
    required this.index,
    required this.entryId,
    super.key,
  });

  final int index;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const SizedBox(width: 4),
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: ReorderableDragStartListener(
              index: index,
              child: const Iconify(TWIcons.barsStaggered, size: 12),
            ),
          ),
          const SizedBox(width: 8),
          EntryNode(
            entryId: entryId,
            contextActions: ref.watch(_entryContextActionsProvider(entryId)),
          ),
          _SmartSpacer(entryId: entryId),
          VerticalDivider(color: Colors.grey.shade900, thickness: 2),
          Expanded(child: _EntryTrack(entryId: entryId)),
        ],
      ),
    );
  }
}

//</editor-fold>

//<editor-fold desc="Segment Tracks">
class _EntryTrack extends HookConsumerWidget {
  const _EntryTrack({
    required this.entryId,
  });

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentKey = useGlobalKey();
    final paths = ref.watch(_segmentPathsProvider(entryId));
    if (paths.isEmpty) return const SizedBox.shrink();

    final offset = ref.watch(_trackOffsetProvider);
    final controller = useScrollController(initialScrollOffset: offset);

    useEffect(
      () {
        if (!controller.hasClients) return;
        controller.jumpTo(offset);
        return null;
      },
      [offset],
    );

    return Stack(
      children: [
        const Positioned.fill(child: _TrackBackground()),
        SingleChildScrollView(
          key: parentKey,
          scrollDirection: Axis.horizontal,
          controller: controller,
          child: _child(paths, parentKey),
        ),
      ],
    );
  }

  Widget _child(Map<String, Modifier> paths, GlobalKey parentKey) {
    if (paths.length == 1) {
      return _SegmentsTrack(
        entryId: entryId,
        path: paths.keys.first,
        segmentBuilder: (context, segment) {
          return _SegmentWidget(
            key: Key(segment.truePath),
            parentKey: parentKey,
            entryId: entryId,
            segment: segment,
          );
        },
      );
    } else {
      return Text(" ${paths.keys.join(", ")}");
    }
  }
}

class _FrameField extends HookConsumerWidget {
  const _FrameField({
    required this.path,
    this.title = "",
    this.icon,
    this.hintText = "",
    this.onValidate,
    this.onDone,
  });

  final String path;
  final String title;
  final String? icon;
  final String hintText;
  final String? Function(int)? onValidate;
  final Function(int)? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    final error = useState<String?>(null);

    useFocusedBasedCurrentEditingField(focus, ref.passing, path);

    final value = ref.watch(fieldValueProvider(path));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title.isEmpty ? path.split(".").last : title),
        const SizedBox(height: 1),
        WritersIndicator(
          provider: fieldWritersProvider(path),
          shift: (_) => const Offset(15, 0),
          child: DecoratedTextField(
            focus: focus,
            text: value.toString(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Iconify(icon, size: 18),
                    )
                  : null,
              hintText: hintText,
              errorText: error.value,
            ),
            onDone: (text) {
              final newValue = int.tryParse(text);
              if (newValue == null) return;
              if (onValidate != null) {
                final errorText = onValidate!(newValue);
                error.value = errorText;
                if (errorText != null) return;
              }

              if (onDone != null) {
                onDone?.call(newValue);
              } else {
                ref
                    .read(inspectingEntryDefinitionProvider)
                    ?.updateField(ref.passing, path, newValue);
              }
            },
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

@freezed
class _FrameLine with _$FrameLine {
  const factory _FrameLine({
    required int frame,
    required double offset,
    required bool primary,
  }) = _$__FrameLine;
}

class _Heading extends HookConsumerWidget {
  const _Heading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final longestName = ref.watch(_longestEntryNameProvider);
    final longestNameSize = useTextSize(
      context,
      longestName,
      const TextStyle(
        fontSize: 13,
        fontFamily: "JetBrainsMono",
      ),
    );
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          SizedBox(
            width: longestNameSize.width + 100,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 8),
                const Text(
                  "Track Duration",
                  style: TextStyle(
                    fontSize: 15,
                    fontVariations: [boldWeight],
                  ),
                ),
                const SizedBox(width: 8),
                const _DurationField(),
                VerticalDivider(color: Colors.grey.shade900, thickness: 2),
              ],
            ),
          ),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TrackSliderTrack(),
                SizedBox(height: 4),
                _TrackTimings(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorContents extends HookConsumerWidget {
  const _InspectorContents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentId = ref.watch(inspectingSegmentIdProvider);
    if (segmentId == null) return const SizedBox.shrink();

    final objectBlueprint = ref.watch(_segmentFieldsProvider);
    if (objectBlueprint == null) return const SizedBox.shrink();

    return ObjectEditor(
      path: segmentId,
      objectBlueprint: objectBlueprint,
      defaultExpanded: true,
      ignoreFields: const [
        "startFrame",
        "endFrame",
      ],
    );
  }
}

class _InspectorHeader extends HookConsumerWidget {
  const _InspectorHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(
          inspectingSegmentProvider.select((segment) => segment?.color),
        ) ??
        Theme.of(context).primaryColor;
    return Title(
      title: "Segment Inspector",
      color: color,
    );
  }
}

class _MoveNotifier extends StateNotifier<_MoveState?> {
  _MoveNotifier(this.ref) : super(null);
  final Ref ref;

  void end() {
    state = null;
  }

  void moveSegment(String entryId, Segment segment, double percent) {
    final state = this.state;
    final innerPercent = state?.innerPercent ?? 0.0;
    final oldStartFrame = segment.startFrame;
    final oldEndFrame = segment.endFrame;

    final newFrame = _getFrameFromPercent(percent);
    final oldFrame =
        ((oldEndFrame - oldStartFrame) * innerPercent + oldStartFrame).round();

    final frameDiff = newFrame - oldFrame;
    if (frameDiff == 0) return;

    final newStartFrame = oldStartFrame + frameDiff;
    final newEndFrame = oldEndFrame + frameDiff;

    if (newEndFrame < newStartFrame) return;
    if (newStartFrame == oldStartFrame && newEndFrame == oldEndFrame) return;
    if (newStartFrame < 0) return;

    final totalFrameCount = ref.read(_trackStateProvider).totalFrames;
    if (newEndFrame > totalFrameCount) return;

    final previousSegment = state?.previousSegment;
    if (previousSegment != null && newStartFrame < previousSegment.endFrame) {
      // We can't move the segment as it would overlap with the previous segment.
      // If we go over the previous segment, we move the the segment and update the move state to reflect the new segment.

      if (newEndFrame > previousSegment.startFrame) return;

      start(entryId, segment, percent);
    }

    final nextSegment = state?.nextSegment;
    if (nextSegment != null && newEndFrame > nextSegment.startFrame) {
      // We can't move the segment as it would overlap with the next segment.
      // If we go over the next segment, we move the the segment and update the move state to reflect the new segment.

      if (newStartFrame < nextSegment.endFrame) return;

      start(entryId, segment, percent);
    }

    final startFramePath = "${segment.truePath}.startFrame";
    final endFramePath = "${segment.truePath}.endFrame";

    _updateEntry(entryId, startFramePath, newStartFrame);
    _updateEntry(entryId, endFramePath, newEndFrame);
  }

  void start(String entryId, Segment segment, [double innerPercent = 0.0]) {
    final segments = ref.read(_segmentsProvider(entryId, segment.path));

    final previousSegment = segments
        .where((s) => s.endFrame <= segment.startFrame)
        .maxBy((_, s) => s.endFrame);
    final nextSegment = segments
        .where((s) => s.startFrame >= segment.endFrame)
        .minBy((_, s) => s.startFrame);

    state = _MoveState(
      previousSegment: previousSegment,
      nextSegment: nextSegment,
      innerPercent: innerPercent,
    );

    ref
        .read(inspectingSegmentIdProvider.notifier)
        .select(entryId, segment.truePath);
  }

  void updateSegmentEnd(String entryId, Segment segment, double percent) {
    final frame = _getFrameFromPercent(percent);
    if (frame == segment.endFrame) return;
    if (frame < segment.startFrame) return;

    if (segment.minFrames != null &&
        frame - segment.startFrame < segment.minFrames!) {
      return;
    }
    if (segment.maxFrames != null &&
        frame - segment.startFrame > segment.maxFrames!) {
      return;
    }

    final nextSegment = state?.nextSegment;
    if (nextSegment != null && frame > nextSegment.startFrame) return;

    final showThumbs = ref.read(_showThumbsProvider(segment.startFrame, frame));
    if (!showThumbs) return;

    final path = "${segment.truePath}.endFrame";
    _updateEntry(entryId, path, frame);
  }

  void updateSegmentStart(String entryId, Segment segment, double percent) {
    final frame = _getFrameFromPercent(percent);
    if (frame == segment.startFrame) return;
    if (frame > segment.endFrame) return;

    if (segment.minFrames != null &&
        segment.endFrame - frame < segment.minFrames!) {
      return;
    }
    if (segment.maxFrames != null &&
        segment.endFrame - frame > segment.maxFrames!) {
      return;
    }

    final previousSegment = state?.previousSegment;
    if (previousSegment != null && frame < previousSegment.endFrame) return;

    final showThumbs = ref.read(_showThumbsProvider(frame, segment.endFrame));
    if (!showThumbs) return;

    final path = "${segment.truePath}.startFrame";
    _updateEntry(entryId, path, frame);
  }

  int _getFrameFromPercent(double percent) {
    final startFrame =
        ref.read(_trackStateProvider.select((state) => state.startFrame));
    final endFrame =
        ref.read(_trackStateProvider.select((state) => state.endFrame));

    final frameCount = endFrame - startFrame;
    final frame = (frameCount * percent).round();
    return frame + startFrame;
  }

  void _updateEntry(String entryId, String path, dynamic value) {
    final page = ref.read(currentPageProvider);
    if (page == null) return;
    final entry = ref.read(entryProvider(page.id, entryId));
    if (entry == null) return;
    page.updateEntryValue(ref.passing, entry, path, value);
  }
}

@freezed
class _MoveState with _$MoveState {
  const factory _MoveState({
    required Segment? previousSegment,
    required Segment? nextSegment,
    @Default(0.0) double innerPercent,
  }) = _$__MoveState;
}

class _SegmentDurationDisplay extends HookConsumerWidget {
  const _SegmentDurationDisplay();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startTime =
        ref.watch(inspectingSegmentProvider.select((s) => s?.startFrame)) ?? 0;
    final endTime =
        ref.watch(inspectingSegmentProvider.select((s) => s?.endFrame)) ??
            startTime;
    final totalTime = endTime - startTime;
    final totalDuration = Duration(milliseconds: totalTime * 50);
    final secondsWithDecimal = totalDuration.inMilliseconds / 1000;

    return Text(
      "Total Duration: $secondsWithDecimal seconds ($totalTime frames)",
      style: Theme.of(context).textTheme.bodySmall?.apply(
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
    );
  }
}

class _SegmentInspector extends HookConsumerWidget {
  const _SegmentInspector({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(inspectingSegmentProvider);
    if (segment == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InspectorHeader(),
          const Divider(),
          if (segment.isSingleFrame)
            const _SingleFrameField()
          else ...[
            const _StartFrameField(),
            const SizedBox(height: 8),
            const _EndFrameField(),
            const SizedBox(height: 8),
            const _SegmentDurationDisplay(),
          ],
          const Divider(),
          const _InspectorContents(),
          const Divider(),
          const _SegmentOperations(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SegmentOperations extends HookConsumerWidget {
  const _SegmentOperations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: "Operations"),
        SizedBox(height: 8),
        _DuplicateSegment(),
        SizedBox(height: 8),
        _DeleteSegment(),
      ],
    );
  }
}

class _SegmentPosition extends HookConsumerWidget {
  const _SegmentPosition({
    required this.segment,
    required this.child,
  });
  final Segment segment;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOffset =
        ref.watch(_frameStartOffsetProvider(segment.startFrame));
    final endOffset = ref.watch(_frameEndOffsetProvider(segment.endFrame));

    if (segment.startFrame == segment.endFrame) {
      final frameSpacing = ref.watch(_frameSpacingProvider);
      return Positioned(
        left: startOffset - frameSpacing / 2,
        right: endOffset - frameSpacing / 2,
        child: child,
      );
    }

    return Positioned(
      left: startOffset,
      right: endOffset,
      child: child,
    );
  }
}

class _SegmentSelector extends HookConsumerWidget {
  const _SegmentSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryId = ref.watch(inspectingEntryIdProvider);
    if (entryId == null) return const SizedBox.shrink();
    final segments = ref.watch(_allSegmentsProvider(entryId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Segments"),
        const SizedBox(height: 8),
        if (segments.isEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            padding: const EdgeInsets.all(8),
            child: const Center(child: Text("No segments")),
          ),
        ] else ...[
          for (final segment in segments)
            _SegmentSelectorTile(segment: segment),
        ],
      ],
    );
  }
}

class _SegmentSelectorTile extends HookConsumerWidget {
  const _SegmentSelectorTile({
    required this.segment,
  });
  final Segment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryId = ref.watch(inspectingEntryIdProvider);
    if (entryId == null) return const SizedBox.shrink();
    final color = segment.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ContextMenuRegion(
        builder: (context) => [
          ContextMenuTile.button(
            title: "Select",
            icon: TWIcons.checkSquare,
            onTap: () {
              ref
                  .read(inspectingSegmentIdProvider.notifier)
                  .select(entryId, segment.truePath);
            },
          ),
          ContextMenuTile.button(
            title: "Duplicate",
            icon: TWIcons.duplicate,
            onTap: () {
              _duplicateSelectedSegment(ref.passing);
            },
          ),
          ContextMenuTile.button(
            title: "Delete",
            icon: TWIcons.trash,
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              deleteSegmentConfirmation(
                context,
                ref.passing,
                entryId,
                segment.truePath,
              );
            },
          ),
        ],
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () {
              ref
                  .read(inspectingSegmentIdProvider.notifier)
                  .select(entryId, segment.truePath);
            },
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Iconify(
                    segment.icon,
                    size: 16,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Segment ${segment.display}",
                    style: TextStyle(
                      fontSize: 14,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Iconify(
                    TWIcons.angleRight,
                    size: 12,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentsTrack extends HookConsumerWidget {
  const _SegmentsTrack({
    required this.entryId,
    required this.path,
    required this.segmentBuilder,
  });
  final String entryId;

  final String path;
  final Widget Function(BuildContext, Segment) segmentBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = ref.watch(_segmentsProvider(entryId, path));
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(width: ref.watch(_trackSizeProvider), height: 64),
        for (final segment in segments)
          _SegmentPosition(
            segment: segment,
            child: segmentBuilder(context, segment),
          ),
      ],
    );
  }
}

class _SegmentWidget extends HookConsumerWidget {
  const _SegmentWidget({
    required this.entryId,
    required this.segment,
    required this.parentKey,
    super.key,
  });
  final String entryId;

  final Segment segment;
  final GlobalKey parentKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localKey = useGlobalKey();
    final grabbing = useState(false);
    final showThumbs =
        ref.watch(_showThumbsProvider(segment.startFrame, segment.endFrame));
    final isPathSelected = ref.watch(
      inspectingSegmentIdProvider.select((id) => id == segment.truePath),
    );
    final isEntrySelected =
        ref.watch(inspectingEntryIdProvider.select((id) => id == entryId));
    final isSelected = isPathSelected && isEntrySelected;

    return WritersIndicator(
      provider: segmentWritersProvider(entryId, segment.truePath),
      child: ContextMenuRegion(
        builder: (context) => [
          ContextMenuTile.button(
            title: "Duplicate",
            icon: TWIcons.duplicate,
            onTap: () => _duplicateSelectedSegment(ref.passing),
          ),
          ContextMenuTile.button(
            title: "Delete",
            icon: TWIcons.trash,
            color: Theme.of(context).colorScheme.error,
            onTap: () {
              final segmentId = ref.read(inspectingSegmentIdProvider);
              if (segmentId == null) return;
              final entryId = ref.read(inspectingEntryIdProvider);
              if (entryId == null) return;

              deleteSegmentConfirmation(
                context,
                ref.passing,
                entryId,
                segmentId,
              );
            },
          ),
        ],
        child: Container(
          height: 16,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: context.isDark
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.4),
                    width: 2,
                  )
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              if (showThumbs) ...[
                const SizedBox(width: 3),
                _Thumb(
                  key: ValueKey("${segment.truePath}.start"),
                  onDragStart: (_) => ref
                      .read(_moveNotifierProvider.notifier)
                      .start(entryId, segment),
                  onDragUpdate: (update) {
                    final percent = _getPercentFromDragUpdate(update, -5);
                    ref
                        .read(_moveNotifierProvider.notifier)
                        .updateSegmentStart(entryId, segment, percent);
                  },
                  onDragEnd: (_) =>
                      ref.read(_moveNotifierProvider.notifier).end(),
                ),
              ],
              Expanded(
                key: localKey,
                child: GestureDetector(
                  onHorizontalDragStart: (details) {
                    grabbing.value = true;
                    final innerPercent =
                        _getPercent(localKey, details.globalPosition);

                    ref
                        .read(_moveNotifierProvider.notifier)
                        .start(entryId, segment, innerPercent);
                  },
                  onHorizontalDragEnd: (details) {
                    grabbing.value = false;
                    ref.read(_moveNotifierProvider.notifier).end();
                  },
                  onHorizontalDragUpdate: (details) {
                    final percent = _getPercentFromDragUpdate(details);

                    ref
                        .read(_moveNotifierProvider.notifier)
                        .moveSegment(entryId, segment, percent);
                  },
                  onTap: () {
                    ref
                        .read(inspectingSegmentIdProvider.notifier)
                        .select(entryId, segment.truePath);
                  },
                  child: MouseRegion(
                    cursor: grabbing.value
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.click,
                    child: Container(),
                  ),
                ),
              ),
              if (showThumbs) ...[
                _Thumb(
                  key: ValueKey("${segment.truePath}.end"),
                  onDragStart: (_) => ref
                      .read(_moveNotifierProvider.notifier)
                      .start(entryId, segment),
                  onDragUpdate: (update) {
                    final percent = _getPercentFromDragUpdate(update, 13);
                    ref
                        .read(_moveNotifierProvider.notifier)
                        .updateSegmentEnd(entryId, segment, percent);
                  },
                  onDragEnd: (_) =>
                      ref.read(_moveNotifierProvider.notifier).end(),
                ),
                const SizedBox(width: 3),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _getPercent(
    GlobalKey key, [
    Offset offset = Offset.zero,
    double shift = 0,
  ]) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0;

    final localPosition = renderBox.globalToLocal(offset);
    final percent = (localPosition.dx + shift) / renderBox.size.width;
    return percent.clamp(0, 1);
  }

  double _getPercentFromDragUpdate(
    DragUpdateDetails details, [
    double shift = 0,
  ]) {
    return _getPercent(parentKey, details.globalPosition, shift);
  }
}

class _SingleFrameField extends HookConsumerWidget {
  const _SingleFrameField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentId = ref.watch(inspectingSegmentIdProvider);

    if (segmentId == null) return const SizedBox.shrink();

    return _FrameField(
      title: "Frame",
      path: "$segmentId.startFrame",
      icon: TWIcons.stepForward,
      hintText: "Enter a frame number",
      onValidate: (frame) {
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId == null) return "No entry selected";
        final segment = ref.read(inspectingSegmentProvider);
        if (segment == null) return "No segment selected";

        final segments = ref.read(_segmentsProvider(entryId, segmentId.wild()));
        if (segments
            .where((s) => s.truePath != segmentId)
            .any((s) => s.startFrame == frame)) {
          return "A segment already exists at this frame";
        }
        return null;
      },
      onDone: (frame) {
        ref
            .read(inspectingEntryDefinitionProvider)
            ?.updateField(ref.passing, "$segmentId.startFrame", frame);
        ref
            .read(inspectingEntryDefinitionProvider)
            ?.updateField(ref.passing, "$segmentId.endFrame", frame + 1);
      },
    );
  }
}

class _SmartSpacer extends HookConsumerWidget {
  const _SmartSpacer({
    required this.entryId,
  });
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final longestName = ref.watch(_longestEntryNameProvider);
    final longestNameSize = useTextSize(
      context,
      longestName,
      const TextStyle(fontSize: 13),
    );
    final entryName = ref.watch(entryNameProvider(entryId));
    final entryNameSize = useTextSize(
      context,
      entryName ?? "",
      const TextStyle(fontSize: 13),
    );

    return SizedBox(
      width: longestNameSize.width - entryNameSize.width,
    );
  }
}

class _StartFrameField extends HookConsumerWidget {
  const _StartFrameField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentId = ref.watch(inspectingSegmentIdProvider);

    if (segmentId == null) return const SizedBox.shrink();

    return _FrameField(
      title: "Start Frame",
      path: "$segmentId.startFrame",
      icon: TWIcons.stepBackward,
      hintText: "Enter a frame number",
      onValidate: (frame) {
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId == null) return "No entry selected";
        final segment = ref.read(inspectingSegmentProvider);
        if (segment == null) return "No segment selected";

        if (frame > segment.endFrame) return "Cannot be after end frame";

        if (segment.minFrames != null &&
            segment.endFrame - frame < segment.minFrames!) {
          return "The segment must be at least ${segment.minFrames} frames long";
        }
        if (segment.maxFrames != null &&
            segment.endFrame - frame > segment.maxFrames!) {
          return "The segment must be at most ${segment.maxFrames} frames long";
        }

        final segments = ref.read(_segmentsProvider(entryId, segmentId.wild()));
        final previousSegment = segments
            .where((s) => s.endFrame <= segment.startFrame)
            .maxBy((_, s) => s.endFrame);
        final minimumFrame = previousSegment?.endFrame ?? 0;
        if (frame < minimumFrame) return "Cannot overlap with previous segment";
        return null;
      },
    );
  }
}

//</editor-fold>

class _Thumb extends HookConsumerWidget {
  const _Thumb({
    required this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
    super.key,
  });
  final Function(DragStartDetails)? onDragStart;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: onDragStart,
        onHorizontalDragUpdate: onDragUpdate,
        onHorizontalDragEnd: onDragEnd,
        child: Container(
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _TrackBackground extends HookConsumerWidget {
  const _TrackBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(_trackBackgroundLinesProvider);
    return CustomPaint(
      painter: _BackgroundLinePainter(lines: lines),
    );
  }
}

class _TrackSlider extends HookConsumerWidget {
  const _TrackSlider({
    required this.outerKey,
  });
  final GlobalKey outerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(_sliderStartOffsetProvider);
    final end = ref.watch(_sliderEndOffsetProvider);

    final grabbing = useState(false);

    return Positioned(
      height: 16,
      left: start,
      right: end,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 3),
            _Thumb(
              onDragUpdate: (details) {
                final percentage =
                    _percentage(outerKey, details, innerMargin: 10);
                ref.read(_trackStateProvider.notifier).updateStart(percentage);
              },
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragStart: (details) => grabbing.value = true,
                onHorizontalDragEnd: (details) => grabbing.value = false,
                onHorizontalDragUpdate: (details) {
                  if (!_isWithinSlider(outerKey, details, innerMargin: 20)) {
                    return;
                  }
                  ref.read(_trackStateProvider.notifier).drag(details);
                },
                child: MouseRegion(
                  cursor: grabbing.value
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
                  child: Container(),
                ),
              ),
            ),
            _Thumb(
              onDragUpdate: (details) {
                final percentage =
                    _percentage(outerKey, details, innerMargin: -10);
                ref.read(_trackStateProvider.notifier).updateEnd(percentage);
              },
            ),
            const SizedBox(width: 3),
          ],
        ),
      ),
    );
  }

  bool _isWithinSlider(
    GlobalKey key,
    DragUpdateDetails details, {
    double innerMargin = 0,
  }) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final local = renderBox.globalToLocal(details.globalPosition);
    return local.dx >= innerMargin &&
        local.dx <= renderBox.size.width - innerMargin;
  }

  double _percentage(
    GlobalKey key,
    DragUpdateDetails details, {
    double innerMargin = 0,
  }) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0;
    final local = renderBox.globalToLocal(details.globalPosition);
    final width = renderBox.size.width;
    final percentage = (local.dx - innerMargin) / width;
    return percentage.clamp(0, 1);
  }
}

//<editor-fold desc="Track Slider">
class _TrackSliderTrack extends HookConsumerWidget {
  const _TrackSliderTrack();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outerKey = useGlobalKey();

    return LayoutBuilder(
      builder: (context, constraints) {
        ref
            .watch(_trackStateProvider.notifier)
            .delayedWidthChanged(constraints.maxWidth);
        return SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                key: outerKey,
                height: 16,
                left: 0,
                right: 0,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              _TrackSlider(outerKey: outerKey),
            ],
          ),
        );
      },
    );
  }
}

@freezed
class _TrackState with _$TrackState {
  const factory _TrackState([
    // ignore: unused_element_parameter
    @Default(0) double start,
    // ignore: unused_element_parameter
    @Default(1) double end,
    // ignore: unused_element_parameter
    @Default(0) int totalFrames,
    // ignore: unused_element_parameter
    @Default(0) double width,
  ]) = _$__TrackState;
}

class _TrackStateProvider extends StateNotifier<_TrackState> {
  _TrackStateProvider(this.ref) : super(const _TrackState()) {
    state = state.copyWith(
      totalFrames: max(100, ref.read(_totalSequenceFramesProvider)),
    );
  }
  static const _minWidth = 40;
  final Ref ref;
  double calculateDelta(double delta) => delta / state.width;

  void changeTotalFrames(int totalFrames) {
    state = state.copyWith(totalFrames: totalFrames);
  }

  Future<void> delayedWidthChanged(double width) async {
    if (width == state.width) return;
    await Future.delayed(const Duration(milliseconds: 100));
    widthChanged(width);
  }

  void drag(DragUpdateDetails details) {
    if (details.delta.dx == 0) return;

    final widthDelta = calculateDelta(details.delta.dx);
    final newStart = state.start + widthDelta;
    final newEnd = state.end + widthDelta;
    if (newStart < 0) return;
    if (newEnd > 1) return;
    state = state.copyWith(start: newStart, end: newEnd);
  }

  void updateEnd(double newEnd) {
    if (newEnd > 1) return;
    if (newEnd < state.start) return;
    final size = (newEnd - state.start) * state.width;
    if (size < _minWidth) return;
    state = state.copyWith(end: newEnd);
  }

  void updateStart(double newStart) {
    if (newStart < 0) return;
    if (newStart > state.end) return;
    final size = (state.end - newStart) * state.width;
    if (size < _minWidth) return;
    state = state.copyWith(start: newStart);
  }

  void widthChanged(double width) {
    if (width == state.width) return;
    state = state.copyWith(width: width, start: 0, end: 1);
  }
}

class _TrackTimings extends HookConsumerWidget {
  const _TrackTimings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fractionFrames = ref.watch(_timeFractionFramesProvider());
    final oneCharWidth =
        useTextSize(context, "0", const TextStyle(fontSize: 10)).width;

    return SizedBox(
      height: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final frame in fractionFrames)
            Positioned(
              left: ref.watch(
                _timePointOffsetProvider(
                  frame,
                  oneCharWidth * frame.toString().length,
                ),
              ),
              child: Text(
                frame.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on _TrackState {
  int get duration => endFrame - startFrame;
  int get endFrame => (end * totalFrames).round().clamp(0, totalFrames);
  int get startFrame => (start * totalFrames).round().clamp(0, totalFrames);
}

extension on Map<String, Modifier> {
  Modifier? findModifier(String path) {
    return this[path.wild()];
  }
}
//</editor-fold>
