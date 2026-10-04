import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Composes the selected resources into one inspector presentation graph.
///
/// [EditorOwnerRegistry] is the authority for resource editor owners and keeps
/// those owners, drafts, and persistence state across graph refreshes. This
/// session owns only the current composite graph. Refreshes stage a new owner
/// set and graph, then commit both together; failed builds roll back staged
/// owners and preserve the installed graph.
///
/// Selection is read from [selectedProvider]. Focus is deliberately unrelated:
/// selectable surfaces own focus, while this session reacts only to selection
/// resolution and resource availability.
final class InspectionSession extends ChangeNotifier {
  InspectionSession(this.ref)
    : owners = EditorOwnerRegistry(
        workspace: ref.read(localWorkControllerProvider),
      ) {
    ref.listen(inspectedSelectionProvider, (_, next) {
      if (next.asError?.error case SelectableNotFoundException(:final id)) {
        owners.deleted(id);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) ref.read(selectionProvider.notifier).unselect(id);
        });
        SchedulerBinding.instance.ensureVisualUpdate();
      } else if (next.isLoading || next.hasError) {
        owners.unavailable(
          next.hasError
              ? "The selected resources could not be refreshed"
              : "The selected resources are refreshing",
        );
        notifyListeners();
      } else {
        _refresh();
      }
    });
    _refresh();
  }
  final Ref ref;
  bool _disposed = false;
  final EditorOwnerRegistry owners;
  InspectionBuildContext? _buildContext;

  Widget? header;
  List<PortablePresentationHost> hosts = const [];
  Widget? body;

  void _refresh() {
    final selection = ref.read(inspectedSelectionProvider).value;
    if (selection == null) return;

    final router = ref.read(appRouterProvider);
    final path = router.currentPath;
    final container = ref.container;

    owners.destinationFor = (identity) => InspectorDestination(
      container: container,
      router: router,
      path: path,
      identity: identity,
    );

    final refresh = owners.beginRefresh();
    final next = InspectionBuildContext(refresh);
    var committed = false;
    try {
      final content = _buildSelection(selection, next);

      refresh.commit();
      committed = true;
      final previous = _buildContext;
      _buildContext = next;
      header = content?.header;
      hosts = content == null
          ? const []
          : [content.host, ...content.additionalHosts].nonNulls.toList();
      body = content?.body;
      previous?.releaseHosts(hosts);
      previous?.dispose();
      notifyListeners();
    } on Object {
      if (!committed) {
        next.dispose();
        refresh.rollback();
      }
      rethrow;
    } finally {
      refresh.dispose();
    }
  }

  InspectionContent? _buildSelection(
    List<InspectableSelectable> selection,
    InspectionBuildContext context,
  ) {
    if (selection.isEmpty) return null;
    if (selection.length == 1) {
      return context.ownHosts(selection.single.buildInspection(context.owners));
    }

    if (_buildSharedPortable(selection, context) case final content?) {
      return context.ownHosts(content);
    }

    return _buildStructural(selection, context);
  }

  InspectionContent? _buildSharedPortable(
    List<InspectableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final candidates = selection
        .map(
          (item) =>
              _indexPortableSurfaces(item.portableMultiInspectionSurfaces),
        )
        .toList();
    if (candidates.any((surfaces) => surfaces.isEmpty)) return null;

    final plans = <_PortableMultiInspectionPlan>[];
    for (final id in candidates.first.keys) {
      final members = [for (final surfaces in candidates) ?surfaces[id]];
      if (members.length != selection.length) continue;
      final first = members.first;
      if (members.any(
        (candidate) =>
            !first.isCompatibleWith(candidate) ||
            !candidate.isCompatibleWith(first),
      )) {
        continue;
      }
      final rootType = members
          .map((candidate) => candidate.rootType)
          .commonEditableProjection()
          .valueOrNull;
      if (rootType == null) continue;
      final catalog = _mergePortableCatalogs(members);
      if (catalog == null) continue;
      plans.add(
        _PortableMultiInspectionPlan(
          members: members,
          rootType: rootType,
          typeCatalog: catalog,
        ),
      );
    }
    if (plans.isEmpty) return null;

    final hosts = <PortablePresentationHost>[];
    for (final plan in plans) {
      final owners =
          (Set<EditorSource>.identity()..addAll(
                plan.members.map(
                  (surface) => context.owners.editor(surface.target),
                ),
              ))
              .toList();
      final combined = context.multiEditorForOwners(
        owners,
        rootType: plan.rootType,
        typeCatalog: plan.typeCatalog,
      );
      final host = plan.members.first.buildHost(
        plan.members,
        combined,
        () async {
          await Future.wait(owners.map((owner) => owner.flush()));
        },
      );
      context.ownHosts(InspectionContent(host: host));
      hosts.add(host);
    }
    return InspectionContent(
      host: hosts.first,
      additionalHosts: hosts.skip(1).toList(),
    );
  }

  InspectionContent _buildStructural(
    List<InspectableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final contents = <InspectionContent>[];
    for (final item in selection) {
      contents.add(context.ownHosts(item.buildInspection(context.owners)));
    }
    final bodies = contents.map((content) => content.body).nonNulls.toList();
    final hosts = [
      for (final content in contents)
        ...[content.host, ...content.additionalHosts].nonNulls,
    ];
    return InspectionContent(
      additionalHosts: hosts,
      body: bodies.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bodies,
            ),
    );
  }

  /// Flushes resource owners retained by the current graph.
  ///
  /// This persists the owners' local drafts according to their commit policy;
  /// it does not change selection or rebuild the presentation graph. When
  /// [failedOnly] is true, only resources reporting a retryable save state are
  /// submitted.
  Future<Map<Object, TypedMutationResult>> flush({bool failedOnly = false}) =>
      owners.flush(failedOnly: failedOnly);

  @override
  void dispose() {
    _disposed = true;
    _buildContext?.dispose();
    owners.dispose();
    super.dispose();
  }
}

Map<Object, PortableMultiInspectionSurface> _indexPortableSurfaces(
  Iterable<PortableMultiInspectionSurface> surfaces,
) {
  final indexed = <Object, PortableMultiInspectionSurface>{};
  for (final surface in surfaces) {
    if (indexed.containsKey(surface.id)) {
      throw StateError("Portable inspection surface ids must be unique");
    }
    indexed[surface.id] = surface;
  }
  return indexed;
}

TypeCatalog? _mergePortableCatalogs(
  List<PortableMultiInspectionSurface> surfaces,
) {
  final definitions = <ResolvedTypeRef, TypeDefinition>{};
  for (final surface in surfaces) {
    for (final definition in surface.typeCatalog.definitions) {
      final existing = definitions[definition.id];
      if (existing != null && existing != definition) return null;
      definitions[definition.id] = definition;
    }
  }
  return TypeCatalog(definitions.values.toList());
}

final class _PortableMultiInspectionPlan {
  const _PortableMultiInspectionPlan({
    required this.members,
    required this.rootType,
    required this.typeCatalog,
  });

  final List<PortableMultiInspectionSurface> members;
  final TypeExpression rootType;
  final TypeCatalog typeCatalog;
}

/// Restores a resource selection and its route without retaining an inspector.
///
/// Editor resources use this destination after the inspector graph is rebuilt
/// or closed. It observes route and selection state, but owns neither; closing
/// it releases only those listeners.
final class InspectorDestination extends EditorDestination {
  InspectorDestination({
    required this.container,
    required this.router,
    required this.path,
    required this.identity,
  }) {
    router.addListener(notifyListeners);
    _selection = container.listen(
      selectionProvider,
      (_, _) => notifyListeners(),
    );
  }

  final ProviderContainer container;
  final AppRouter router;
  final String path;
  final Object identity;
  late final ProviderSubscription<List<SelectableIdentifier>> _selection;

  @override
  bool get isCurrent =>
      router.currentPath == path &&
      (identity is! SelectableIdentifier ||
          container.read(selectionProvider).contains(identity));

  /// Navigates to the saved route and selects the saved resource, if any.
  @override
  Future<void> open() async {
    if (router.currentPath != path) await router.navigatePath(path);
    if (identity case final SelectableIdentifier selected) {
      container.read(selectionProvider.notifier).selectAll([selected]);
    }
  }

  @override
  void dispose() {
    router.removeListener(notifyListeners);
    _selection.close();
    super.dispose();
  }
}
