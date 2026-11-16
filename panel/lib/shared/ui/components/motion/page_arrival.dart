import "package:typewriter_panel/typewriter_panel.dart";

/// The side a page change comes from: deeper and back by path depth,
/// down and up between sidebar siblings.
enum PageDirection { deeper, back, down, up }

/// One page change: its [direction], the route key of the page it reached,
/// and a [serial] that is new for every change, so a kept page replays.
@immutable
final class PageMove {
  const PageMove({
    required this.direction,
    required this.target,
    required this.serial,
  });

  final PageDirection direction;
  final String target;
  final int serial;
}

/// The page move that reached this page, or none; Enter reads it to come
/// from the move's side and to replay when a new move arrives.
class PageArrival extends InheritedWidget {
  const PageArrival({required this.move, required super.child, super.key});

  final PageMove? move;

  static PageMove? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageArrival>()?.move;

  @override
  bool updateShouldNotify(PageArrival oldWidget) =>
      move?.serial != oldWidget.move?.serial;
}
