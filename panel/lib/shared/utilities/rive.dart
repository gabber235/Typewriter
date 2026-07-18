import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/shared/hooks/rive.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_panel/shared/utilities/test_environment.dart";

class RiveAsset extends StatelessWidget {
  const RiveAsset({
    required this.asset,
    required this.stateMachineName,
    this.placeholder = const SizedBox.shrink(),
    this.builder,
    super.key,
  });

  final String asset;
  final String stateMachineName;
  final Widget placeholder;
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

/// Extension on [RiveState] for convenient widget building with loading and error states.
extension RiveStateExtension on RiveState {
  /// Builds a widget based on the current [RiveState].
  ///
  /// - [builder]: Called when the Rive file is loaded successfully.
  /// - [size]: The size for the loading shimmer (defaults to 100x100).
  /// - [loading]: Optional custom loading widget builder.
  /// - [error]: Optional custom error widget builder.
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
      borderRadius: BorderRadius.circular(8),
    );
  }
}

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
        borderRadius: BorderRadius.circular(8),
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
            style: TextStyle(
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
