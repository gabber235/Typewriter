import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps pending field reveals alive while routes within one Realm change.
/// Leaving the Realm releases its controller and any unresolved request.
class RealmNavigationBoundary extends ConsumerWidget {
  const RealmNavigationBoundary({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    if (scope != null) {
      ref.watch(realmLocationRevealProvider(scope));
    }
    return child;
  }
}
