import "package:typewriter_panel/typewriter_panel.dart";

/// Marks [child], the Activity button, as where a landing toast flies to.
class ToastLandingTarget extends HookConsumerWidget {
  const ToastLandingTarget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = useMemoized(GlobalKey.new);
    final landing = ref.watch(toastLandingProvider);
    useEffect(() {
      landing.target = key;
      return () {
        if (landing.target == key) landing.target = null;
      };
    }, [landing]);
    return KeyedSubtree(key: key, child: child);
  }
}
