import "dart:math";

import "package:flutter/material.dart" hide Title;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:okcolor/models/extensions.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/utils/animation.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/outline_decorator.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";

const bookWidth = 175.0;
const bookHeight = 230.0;
const bookAspectRatio = bookWidth / bookHeight;

/// Displays a selectable animated book.
class BookWidget extends HookConsumerWidget {
  const BookWidget({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.tags = const [],
    super.key,
  });

  final String id;
  final String title;
  final Widget icon;
  final Color color;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final selectableId = BookIdentifier(id);

    return Selector(
      selectableId: selectableId,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        return Surface(
          color: Theme.of(context).colorScheme.surface,
          child:
              OutlineDecorator(
                    show: isFocused,
                    outerColor: color,
                    innerColor: Surface.colorOf(context),
                    builder: (context) => SizedBox(
                      width: bookWidth,
                      height: bookHeight,
                      child: _BookStack(
                        key: const ValueKey("content"),
                        color: color,
                        icon: icon,
                        title: title,
                        tags: tags,
                        isSelected: isSelected,
                      ),
                    ),
                  )
                  .animate(target: isHovered ? 1 : 0)
                  .hoverScale(isHovered)
                  .hoverRotate(isHovered),
        );
      },
    );
  }
}

class _BookStack extends StatelessWidget {
  const _BookStack({
    required this.color,
    required this.icon,
    required this.title,
    required this.tags,
    required this.isSelected,
    super.key,
  });

  final Color color;
  final Widget icon;
  final String title;
  final List<Tag> tags;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _SpineLayers(isSelected: isSelected, color: color),
        Positioned.fill(
          child: _BookCover(
            isSelected: isSelected,
            color: color,
            icon: icon,
            title: title,
            tags: tags,
          ),
        ),
      ],
    );
  }
}

class _SpineLayers extends StatelessWidget {
  const _SpineLayers({required this.isSelected, required this.color});

  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final specs = <_SpineSpec>[
      _SpineSpec(
        top: (s) => s ? 15 : 10,
        bottom: (s) => s ? 15 : 10,
        right: (s) => 0,
        color: (c, d) =>
            c.toOkLch().darker(d ? 0.3 : -0.1).desaturate(0.3).toColor(),
      ),
      _SpineSpec(
        top: (s) => s ? 12 : 5,
        bottom: (s) => s ? 12 : 5,
        right: (s) => s ? 4 : 5,
        color: (c, d) =>
            c.toOkLch().darker(d ? 0.1 : -0.3).desaturate(0.3).toColor(),
      ),
      _SpineSpec(
        top: (s) => s ? 10 : 5,
        bottom: (s) => s ? 10 : 5,
        right: (s) => s ? 8 : 5,
        color: (c, d) =>
            c.toOkLch().darker(d ? -0.0 : -0.3).desaturate(0.3).toColor(),
      ),
      _SpineSpec(
        top: (s) => 5,
        bottom: (s) => 5,
        right: (s) => s ? 14 : 5,
        color: (c, d) =>
            c.toOkLch().darker(d ? -0.1 : -0.3).desaturate(0.3).toColor(),
      ),
    ];

    return Stack(
      children: [
        for (final spec in specs)
          _AnimatedSpineLayer(
            spec: spec,
            isSelected: isSelected,
            color: color,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _SpineSpec {
  const _SpineSpec({
    required this.top,
    required this.bottom,
    required this.right,
    required this.color,
  });

  final double Function(bool isSelected) top;
  final double Function(bool isSelected) bottom;
  final double Function(bool isSelected) right;
  final Color Function(Color base, bool isDark) color;
}

class _AnimatedSpineLayer extends StatelessWidget {
  const _AnimatedSpineLayer({
    required this.spec,
    required this.isSelected,
    required this.color,
    required this.isDark,
  });

  final _SpineSpec spec;
  final bool isSelected;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: isSelected ? 750.ms : 300.ms,
      curve: isSelected ? ElasticOutCurve(0.9) : Curves.fastEaseInToSlowEaseOut,
      top: spec.top(isSelected),
      bottom: spec.bottom(isSelected),
      right: spec.right(isSelected),
      child: SizedBox(
        width: 30,
        child: Material(
          color: spec.color(color, isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.title,
    required this.tags,
  });

  final bool isSelected;
  final Color color;
  final Widget icon;
  final String title;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: isSelected ? 750.ms : 300.ms,
      curve: isSelected ? ElasticOutCurve(0.9) : Curves.fastEaseInToSlowEaseOut,
      tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
      builder: (context, t, child) {
        final scale = 1 - 0.1 * t;
        final matrix =
            Matrix4(
                1.0,
                0.0,
                0.0,
                0.0, //
                0.0,
                1.0,
                0.0,
                0.0, //
                0.0,
                0.0,
                1.0,
                0.002 * t, //
                0.0,
                0.0,
                0.0,
                1.0,
              )
              ..rotateY(0.1 * pi * t)
              ..scaleByDouble(scale, scale, 1, 1);
        return Transform(
          alignment: Alignment.centerLeft,
          transform: matrix,
          child: child,
        );
      },
      child: Stack(
        children: [
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
                shape: const RoundedRectangleBorder(
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
              children: [
                _TopRow(icon: icon),
                _TitleText(title: title),
                if (tags.isNotEmpty)
                  _TagsList(color: color, tags: tags)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 16,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white60),
            child: icon,
          ),
        ),
        const Icones(HeroiconsSolid.bars_3_bottom_left, color: Colors.white38),
      ],
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        title.formatted,
        style: TextStyle(
          fontSize: context.responsive(mobile: 12, tablet: 14, desktop: 16),
          fontVariations: [boldWeight],
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TagsList extends StatelessWidget {
  const _TagsList({required this.color, required this.tags});

  final Color color;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final double height = min(
      100.0,
      tags.length * 8.0 + (tags.length - 1) * 5.0 + 8.0,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastEaseInToSlowEaseOut,
      decoration: BoxDecoration(
        color: color
            .toOkLch()
            .darker(isDark ? 0.5 : -0.5)
            .desaturate(isDark ? 0.5 : 0.5)
            .toColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: ListView.separated(
          scrollDirection: Axis.vertical,
          itemCount: tags.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final tag = tags[index];
            return _TagChip(tag: tag, key: Key(tag.tagId));
          },
          separatorBuilder: (context, index) => const SizedBox(height: 5),
        ),
      ),
    );
  }
}

class _TagChip extends HookWidget {
  const _TagChip({required this.tag, super.key});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final tagColor = tag.color.toFlutterColor();

    return Container(
      decoration: ShapeDecoration(color: tagColor, shape: StadiumBorder()),
      height: 8,
    );
  }
}

/// Header for a book displaying title and identifier.
class BookHeader extends HookWidget {
  const BookHeader({
    required this.id,
    required this.name,
    required this.color,
    super.key,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: name, color: color),
        const SizedBox(height: 8),
        Identifier(id: id),
      ],
    );
  }
}
