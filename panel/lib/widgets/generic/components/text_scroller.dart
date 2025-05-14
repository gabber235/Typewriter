import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/text_size.dart";
import "package:typewriter_panel/hooks/timer.dart";

/// Switches between the given texts in a loop.
class TextScroller extends HookWidget {
  const TextScroller({
    required this.texts,
    this.style,
    this.duration = const Duration(seconds: 2),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    super.key,
  }) : super();

  final List<String> texts;
  final TextStyle? style;
  final Duration duration;
  final Duration transitionDuration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController(initialPage: 1);
    useTimer(duration, (_) {
      if (controller.page == texts.length) {
        controller.jumpToPage(0);
      }
      controller.nextPage(duration: transitionDuration, curve: curve);
    });
    final text = maxBy<String, int>(texts, (s) => s.length);
    final size = useTextSize(context, text ?? "", style);

    return SizedBox(
      height: size.height,
      width: size.width,
      child: PageView(
        controller: controller,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final text in [texts.last, ...texts])
            Text(
              text,
              textAlign: TextAlign.center,
              style: style,
            ),
        ],
      ),
    );
  }
}
