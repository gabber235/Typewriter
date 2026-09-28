import "dart:math";

import "package:flutter/material.dart" hide Title;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:okcolor/models/extensions.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const bookWidth = 175.0;
const bookHeight = 230.0;
const bookAspectRatio = bookWidth / bookHeight;

/// Displays a book in the library grid.
///
/// Selection and focus belong to the shared selectable system. Double click
/// opens the book route. The caller supplies projected book data, including
/// already resolved tags.
class BookWidget extends HookConsumerWidget {
  const BookWidget({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.tags = const [],
    super.key,
  });

  final skir.ResourceId id;
  final String title;
  final Widget icon;
  final Color color;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final selectableId = BookIdentifier(id);
    final organization = ref.watch(organizationIdProvider);
    final realm = ref.watch(realmIdProvider);

    return Selector(
      selectableId: selectableId,
      focusNode: focusNode,
      onDoubleTap: organization == null || realm == null
          ? null
          : () => ref
                .read(appRouterProvider)
                .navigate(selectableId.routeFor(organization, realm)),
      builder: (isSelected, isFocused, isHovered) {
        final book = Surface(
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
        return DragTarget<Object>(
          onWillAcceptWithDetails: (details) => details.data is TagIdentifier,
          onAcceptWithDetails: (details) async {
            final data = details.data as ReferenceResourceDragData;
            final current = ref.read(projectedBookProvider(id)).value;
            if (current == null) return;
            final tags = [...current.tagIds];
            final index = tags.indexOf(data.referenceId);
            if (index < 0) {
              tags.add(data.referenceId);
            } else {
              tags.removeAt(index);
            }
            await ref
                .read(canonicalBooksProvider.notifier)
                .updateBook(current.copyWith(tagIds: tags), expected: current);
          },
          builder: (context, accepted, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: context.shapes.largeBorderRadius,
              border: accepted.isEmpty && rejected.isEmpty
                  ? null
                  : Border.all(
                      color: accepted.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      width: 2,
                    ),
            ),
            child: Draggable<BookIdentifier>(
              data: selectableId,
              feedback: Material(
                color: Colors.transparent,
                child: Surface(
                  color: Theme.of(context).colorScheme.surface,
                  child: SizedBox(
                    width: bookWidth,
                    child: Padding(
                      padding: EdgeInsets.all(context.spacing.space4),
                      child: Text(title),
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: book),
              child: book,
            ),
          ),
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
            borderRadius: context.shapes.largeBorderRadius,
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
                borderRadius: context.shapes.largeBorderRadius,
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
                    topLeft: context.shapes.largeRadius,
                    bottomLeft: context.shapes.largeRadius,
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
          width: 28,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white60, size: 28),
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
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
        borderRadius: context.shapes.smallBorderRadius,
      ),
      padding: EdgeInsets.all(context.spacing.space1),
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: ListView.separated(
          scrollDirection: Axis.vertical,
          itemCount: tags.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final tag = tags[index];
            return _TagChip(tag: tag, key: Key(tag.tagId.id));
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
    return Container(
      decoration: ShapeDecoration(color: tag.color, shape: StadiumBorder()),
      height: 8,
    );
  }
}
