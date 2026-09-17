// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Initializes the process wide tracing exporter and exposes the panel tracer.
///
/// Disabled tracing returns [NoopPanelTelemetry] without validating or opening
/// an exporter. Enabled tracing requires an absolute endpoint because an
/// exporter cannot deliver spans to a relative browser or server path.

@ProviderFor(panelTelemetry)
final panelTelemetryProvider = PanelTelemetryProvider._();

/// Initializes the process wide tracing exporter and exposes the panel tracer.
///
/// Disabled tracing returns [NoopPanelTelemetry] without validating or opening
/// an exporter. Enabled tracing requires an absolute endpoint because an
/// exporter cannot deliver spans to a relative browser or server path.

final class PanelTelemetryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PanelTelemetry>,
          PanelTelemetry,
          FutureOr<PanelTelemetry>
        >
    with $FutureModifier<PanelTelemetry>, $FutureProvider<PanelTelemetry> {
  /// Initializes the process wide tracing exporter and exposes the panel tracer.
  ///
  /// Disabled tracing returns [NoopPanelTelemetry] without validating or opening
  /// an exporter. Enabled tracing requires an absolute endpoint because an
  /// exporter cannot deliver spans to a relative browser or server path.
  PanelTelemetryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'panelTelemetryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$panelTelemetryHash();

  @$internal
  @override
  $FutureProviderElement<PanelTelemetry> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PanelTelemetry> create(Ref ref) {
    return panelTelemetry(ref);
  }
}

String _$panelTelemetryHash() => r'd8caec1238ae43dd49eeb8b2e91ccdbb680a1946';
