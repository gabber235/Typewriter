import "package:typewriter_panel/typewriter_panel.dart";

import "work_session_unload_protection_stub.dart"
    if (dart.library.js_interop) "work_session_unload_protection_web.dart";

/// Platform boundary for browser document unload protection.
abstract interface class WorkSessionUnloadProtection {
  factory WorkSessionUnloadProtection() = PlatformWorkSessionUnloadProtection;

  /// Enables the browser warning only while local work requires protection.
  bool get protected;
  set protected(bool value);

  /// Removes every listener owned by this adapter.
  void dispose();
}

/// Keeps browser reload and close protection aligned with local work state.
class WorkSessionUnloadBoundary extends ConsumerWidget {
  const WorkSessionUnloadBoundary({
    required this.child,
    this.protection,
    super.key,
  });

  final Widget child;
  final WorkSessionUnloadProtection? protection;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkSessionUnloadBinding(
    protected: ref.watch(
      localWorkProvider.select((state) => state.blocksNavigation),
    ),
    protection: protection,
    child: child,
  );
}

/// Owns one platform adapter and updates it when protection changes.
class WorkSessionUnloadBinding extends StatefulWidget {
  const WorkSessionUnloadBinding({
    required this.protected,
    required this.child,
    this.protection,
    super.key,
  });

  final bool protected;
  final Widget child;
  final WorkSessionUnloadProtection? protection;

  @override
  State<WorkSessionUnloadBinding> createState() =>
      _WorkSessionUnloadBindingState();
}

final class _WorkSessionUnloadBindingState
    extends State<WorkSessionUnloadBinding> {
  late WorkSessionUnloadProtection _protection;

  @override
  void initState() {
    super.initState();
    _protection = widget.protection ?? WorkSessionUnloadProtection();
    _protection.protected = widget.protected;
  }

  @override
  void didUpdateWidget(WorkSessionUnloadBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.protection, widget.protection)) {
      _protection.dispose();
      _protection = widget.protection ?? WorkSessionUnloadProtection();
    }
    _protection.protected = widget.protected;
  }

  @override
  void dispose() {
    _protection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
