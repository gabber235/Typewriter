import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A presentation host that also projects Realm resources and collections,
/// for presentations that show linked resources or authored collections
/// without a Realm behind them.
///
/// Every value read and write goes to [delegate]; [collections] and
/// [resources] answer what the Realm would project.
final class ProjectingHost
    implements PortablePresentationHost, PortableCollectionProjectionHost {
  ProjectingHost(this.delegate, {this.collections, this.resources});

  final PortablePresentationHost delegate;

  /// Projects the collection [sourceId] as the presentation [material]
  /// declares it; null reports every collection unavailable.
  final PortableCollectionProjection Function(
    String sourceId,
    skir.PresentationMaterial material,
  )?
  collections;

  /// Projects one linked resource; null projects none.
  final PortableResourceProjection? Function(skir.ResourceId resource)?
  resources;

  @override
  void dispose() => delegate.dispose();
  @override
  PortablePresentationDocument get document => delegate.document;
  @override
  bool get enabled => delegate.enabled;
  @override
  bool get readOnly => delegate.readOnly;
  @override
  PortablePresentationCapabilities get capabilities => delegate.capabilities;
  @override
  void addListener(VoidCallback listener) => delegate.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      delegate.removeListener(listener);
  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.commitControl(reference, context: context);
  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.read(reference, context: context);
  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.location(reference, context: context);
  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.expectedType(reference, context: context);
  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) => delegate.write(reference, value, context: context);
  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction action, {
    required PortableInvocationContext context,
  }) => delegate.execute(action, context: context);

  @override
  PortableCollectionProjection projectCollection(
    String sourceId, {
    required skir.PresentationMaterial material,
    required PortableInvocationContext context,
  }) =>
      collections?.call(sourceId, material) ??
      PortableCollectionProjection(
        definition: null,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );

  @override
  PortableResourceProjection? projectResource(
    skir.ResourceId resource, {
    required PortableInvocationContext context,
  }) => resources?.call(resource);
}
