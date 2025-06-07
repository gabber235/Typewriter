import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter/iconify_flutter.dart";
import "package:iconify_flutter/icons/heroicons_solid.dart";
import "package:okcolor/models/extensions.dart";
import "package:typewriter_panel/hooks/auto_scroll.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/generic/components/tag.dart";

class BookWidget extends HookWidget {
  const BookWidget({
    required this.title,
    required this.icon,
    required this.color,
    this.tags = const [],
    super.key,
  });

  final String title;
  final Widget icon;
  final Color color;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final inspecting = useState(false);
    final scrollController = useScrollController();
    useAutoScroll(
      scrollController,
      enabled: inspecting.value,
      delay: const Duration(milliseconds: 1000),
      velocity: .02,
      loopingMode: AutoScrollLoopingMode.pingPong,
    );

    return MouseRegion(
      onEnter: (_) => inspecting.value = true,
      onExit: (_) => inspecting.value = false,
      child: SizedBox(
        width: 175,
        height: 230,
        child: Stack(
          children: [
            Positioned(
              top: 10,
              bottom: 10,
              right: 0,
              child: SizedBox(
                width: 30,
                child: Material(
                  color: color
                      .toOkLch()
                      .darker(context.isDarkMode ? 0.3 : -0.1)
                      .desaturate(0.3)
                      .toColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 5,
              bottom: 5,
              right: 5,
              child: SizedBox(
                width: 30,
                child: Material(
                  color: color
                      .toOkLch()
                      .darker(context.isDarkMode ? -0.1 : -0.3)
                      .desaturate(0.3)
                      .toColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              right: 10,
              child: Material(
                color: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SizedBox(
                width: 16,
                child: Material(
                  color: color
                      .toOkLch()
                      .darker(context.isDarkMode ? 0.3 : 0.2)
                      .desaturate(context.isDarkMode ? 0.3 : 0.2)
                      .toColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              bottom: 10,
              left: 24,
              right: 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // spacing: 4,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 16,
                        child: IconTheme(
                          data: IconThemeData(color: Colors.white60),
                          child: icon,
                        ),
                      ),
                      Iconify(
                        HeroiconsSolid.bars_3_bottom_left,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      title.formatted,
                      style: TextStyle(
                        fontSize: context.responsive(
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        fontVariations: [boldWeight],
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (tags.isNotEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastEaseInToSlowEaseOut,
                      decoration: BoxDecoration(
                        color: color
                            .toOkLch()
                            .darker(context.isDarkMode ? 0.5 : -0.5)
                            .desaturate(context.isDarkMode ? 0.5 : 0.5)
                            .toColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(4),
                      height: inspecting.value
                          ? 100
                          : min(
                              100,
                              tags.length * 8 + (tags.length - 1) * 5 + 8,
                            ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: ListView.separated(
                          controller: scrollController,
                          scrollDirection: Axis.vertical,
                          itemCount: tags.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            return TagWidget(
                              tag: tag,
                              isExpanded: inspecting.value,
                              key: Key(tag.id),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return SizedBox(
                              height: inspecting.value ? 10 : 5,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(target: inspecting.value ? 1 : 0)
          .scaleXY(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuad,
            begin: 1.0,
            end: 1.05,
          )
          .rotate(begin: 0, end: 0.005),
    );
  }
}
