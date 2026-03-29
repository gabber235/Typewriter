import "package:flutter/material.dart";
import "package:typewriter_panel/logic/timeline/timeline_placement.dart";
import "package:typewriter_panel/logic/timeline/timeline_viewport.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";

class TimelineTopLeftHeader extends StatelessWidget {
  const TimelineTopLeftHeader({
    required this.viewport,
    required this.style,
    super.key,
  });

  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: style.rulerHeight,
      padding: EdgeInsets.symmetric(horizontal: style.headerPadding),
      decoration: BoxDecoration(
        color: style.palette.headerBackground,
        border: Border(bottom: BorderSide(color: style.palette.headerDivider)),
      ),
      child: Center(child: Text("Timeline", style: textTheme.titleSmall)),
    );
  }
}

class TimelineTrackHeaders extends StatelessWidget {
  const TimelineTrackHeaders({
    required this.placement,
    required this.viewport,
    required this.style,
    super.key,
  });

  final TimelinePlacementResult placement;
  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: style.palette.headerBackground),
        child: Stack(
          children: [
            for (final trackLayout in placement.tracks.where(
              (element) => element.isVisible(viewport),
            ))
              Positioned(
                top: trackLayout.top - viewport.verticalOffset,
                left: 0,
                right: 0,
                height: trackLayout.height,
                child: Container(
                  padding: EdgeInsets.all(style.headerPadding),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: style.palette.headerDivider),
                    ),
                  ),
                  child: trackLayout.track.header(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
