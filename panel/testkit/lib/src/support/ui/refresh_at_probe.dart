import "package:typewriter_panel/typewriter_panel.dart";

/// Shows how often it built, refreshing at [refreshAt] through
/// [useRefreshAt].
final class RefreshAtProbe extends HookWidget {
  const RefreshAtProbe({required this.refreshAt, super.key});

  final DateTime refreshAt;

  @override
  Widget build(BuildContext context) {
    final buildCount = useRef(0);
    buildCount.value++;
    useRefreshAt(refreshAt);
    return Text("${buildCount.value}", textDirection: TextDirection.ltr);
  }
}

/// A [RefreshAtProbe] refreshing at the time [refreshAt] holds now.
final class RefreshAtListenableProbe extends HookWidget {
  const RefreshAtListenableProbe({required this.refreshAt, super.key});

  final ValueNotifier<DateTime> refreshAt;

  @override
  Widget build(BuildContext context) {
    return RefreshAtProbe(refreshAt: useValueListenable(refreshAt));
  }
}
