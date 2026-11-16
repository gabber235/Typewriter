import "package:typewriter_panel/typewriter_panel.dart";

part "toast_landing.g.dart";

/// Where a toast that lands in Activity flies to.
@Riverpod(keepAlive: true)
ToastLanding toastLanding(Ref ref) => ToastLanding();

/// The Activity button a landing toast flies to, if one is on screen. The
/// newest button on screen wins.
final class ToastLanding {
  GlobalKey? target;

  /// Where the target's centre is, from [box]'s centre.
  Offset? towards(RenderBox box) {
    final target = this.target?.currentContext?.findRenderObject();
    if (target is! RenderBox || !target.attached || !box.attached) return null;
    return target.localToGlobal(target.size.center(Offset.zero)) -
        box.localToGlobal(box.size.center(Offset.zero));
  }
}
