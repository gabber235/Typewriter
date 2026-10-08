import "package:typewriter_panel/typewriter_panel.dart";

/// Overlays an asynchronous action button on the lower right of [child].
///
/// While [onPressed] runs, the button disables repeated activation and shows a
/// progress indicator. Exceptions are surfaced through the button state and a
/// snackbar when a scaffold messenger is available; the caller still owns the
/// underlying operation and its durable state.
class FloatingButton extends HookWidget {
  const FloatingButton({
    required this.child,
    required this.icon,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final Widget icon;
  final FutureOr<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final lastError = useState<String?>(null);

    final animation = useForwardAnimation(play: lastError.value != null);

    Future<void> handlePress() async {
      if (onPressed == null || isLoading.value) return;
      isLoading.value = true;
      lastError.value = null;
      try {
        await onPressed!.call();
      } on Exception catch (e) {
        if (!context.mounted) return;
        lastError.value = e.toString();
        final hasScaffold = ScaffoldMessenger.maybeOf(context) != null;
        if (hasScaffold) {
          showErrorSnackBar(context, lastError.value!);
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    final isActive = onPressed != null && !isLoading.value;

    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: 8,
          bottom: 8,
          child: FloatingActionButton(
            onPressed: isActive ? handlePress : null,
            tooltip: lastError.value,
            backgroundColor: lastError.value != null
                ? Theme.of(context).colorScheme.error
                : isActive
                ? null
                : Theme.of(context).disabledColor,
            foregroundColor: lastError.value != null
                ? Theme.of(context).colorScheme.onError
                : isActive
                ? null
                : Theme.of(context).colorScheme.onSurface,
            child: ElasticSwitcher(
              child: isLoading.value ? const _Spinner() : icon,
            ),
          ).animate(controller: animation, autoPlay: false).shakeX(),
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final size = IconTheme.of(context).size ?? 24.0;

    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
