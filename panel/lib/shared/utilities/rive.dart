import "package:typewriter_panel/typewriter_panel.dart";

/// Loads a named Rive state machine, with a deterministic test placeholder.
///
/// Production loading and rendering are delegated to Rive. Tests bypass the
/// asset loader through [placeholder].
class RiveAsset extends StatelessWidget {
  const RiveAsset({
    required this.asset,
    required this.stateMachineName,
    this.placeholder = const SizedBox.shrink(),
    this.builder,
    super.key,
  });

  /// Asset path passed to Rive.
  final String asset;

  /// State machine selected by name after the asset loads.
  final String stateMachineName;

  /// Widget rendered instead of Rive while running in a Flutter test.
  final Widget placeholder;

  /// Optional projection of each loaded Rive state.
  final Widget Function(BuildContext, RiveState)? builder;

  @override
  Widget build(BuildContext context) {
    if (isFlutterTest) return placeholder;

    return _LoadedRiveAsset(
      asset: asset,
      stateMachineName: stateMachineName,
      builder: builder,
    );
  }
}

class _LoadedRiveAsset extends HookWidget {
  const _LoadedRiveAsset({
    required this.asset,
    required this.stateMachineName,
    this.builder,
  });

  final String asset;
  final String stateMachineName;
  final Widget Function(BuildContext, RiveState)? builder;

  @override
  Widget build(BuildContext context) {
    final fileLoader = useRiveFileLoader.fromAsset(asset);
    return RiveWidgetBuilder(
      fileLoader: fileLoader,
      stateMachineSelector: StateMachineSelector.byName(stateMachineName),
      builder: builder ?? (context, state) => state(),
    );
  }
}

/// Builds Rive loading, failure, and loaded states as widgets.
extension RiveStateExtension on RiveState {
  /// Builds a widget based on the current [RiveState].
  ///
  /// [builder] renders a loaded file. [size] controls the loading placeholder.
  /// [loading] and [error] replace the default loading and failure widgets.
  Widget call({
    Widget Function(RiveLoaded state)? builder,
    Size size = Size.infinite,
    Widget Function()? loading,
    Widget Function(Object error)? error,
  }) {
    return switch (this) {
      RiveLoading() =>
        loading != null ? loading() : _RiveLoadingWidget(size: size),
      RiveFailed(error: final e) =>
        error?.call(e) ?? _RiveErrorWidget(error: e),
      RiveLoaded() => HookBuilder(
        builder: (context) =>
            builder?.call(this as RiveLoaded) ??
            RiveWidget(
              controller: (this as RiveLoaded).controller,
              fit: Fit.contain,
            ),
      ),
    };
  }
}

class _RiveLoadingWidget extends StatelessWidget {
  const _RiveLoadingWidget({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox.rectangle(
      width: size.width,
      height: size.height,
      borderRadius: context.shapes.mediumBorderRadius,
    );
  }
}

/// Default failure presentation for an unavailable Rive animation.
class _RiveErrorWidget extends StatelessWidget {
  const _RiveErrorWidget({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: context.shapes.mediumBorderRadius,
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            "Failed to load animation",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
