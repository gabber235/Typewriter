import "package:typewriter_panel/typewriter_panel.dart";

/// Composes the selected resources into one inspector presentation graph.
///
/// The scoped work session owns drafts and persistence. [InspectionBindings]
/// owns view leases across graph refreshes. This session owns the current
/// composite graph. Refreshes acquire prospective leases before releasing the
/// installed graph; failed builds preserve the installed view.
///
/// Selection is read from [selectedProvider]. Focus is deliberately unrelated:
/// selectable surfaces own focus, while this session reacts only to selection
/// resolution and resource availability. Shared surfaces are combined only
/// when every selected resource contributes a mutually compatible surface
/// under the same id. Otherwise each resource keeps its own inspection
/// content.
final class InspectionSession extends ChangeNotifier {
  InspectionSession(this.ref)
    : owners = InspectionBindings(
        workspace: ref.read(localWorkControllerProvider),
      ) {
    ref.listen(inspectedSelectionProvider, (_, next) {
      if (next.isLoading || next.hasError) {
        notifyListeners();
      } else {
        _refresh();
      }
    });
    _refresh();
  }
  final Ref ref;
  final InspectionBindings owners;
  InspectionBuildContext? _buildContext;

  List<PortablePresentationHost> hosts = const [];
  Widget? body;

  void _refresh() {
    final selection = ref.read(inspectedSelectionProvider).value;
    if (selection == null) return;

    final router = ref.read(navigationRouterProvider);
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

    if (_buildShared(selection, context) case final content?) {
      return context.ownHosts(content);
    }

    return _buildStructural(selection, context);
  }

  InspectionContent? _buildShared(
    List<InspectableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final candidates = [
      for (final item in selection)
        _indexSurfaces(item.sharedInspectionSurfaces),
    ];
    final contents = [
      for (final members in _groupsInEvery(candidates))
        members.first.buildShared(members, context),
    ];
    return contents.isEmpty ? null : _combined(contents);
  }

  /// The surfaces that every item of a selection offers under one id, one
  /// group per id, each in selection order, keeping only groups whose
  /// surfaces are all compatible with the first, both ways. None when an
  /// item offers no surface.
  List<List<SharedInspectionSurface>> _groupsInEvery(
    List<Map<Object, SharedInspectionSurface>> candidates,
  ) {
    if (candidates.isEmpty || candidates.any((surfaces) => surfaces.isEmpty)) {
      return const [];
    }
    return [
      for (final id in candidates.first.keys)
        if ([for (final surfaces in candidates) ?surfaces[id]]
            case final members
            when members.length == candidates.length &&
                members.every(
                  (member) =>
                      members.first.isCompatibleWith(member) &&
                      member.isCompatibleWith(members.first),
                ))
          members,
    ];
  }

  InspectionContent _buildStructural(
    List<InspectableSelectable> selection,
    InspectionBuildContext context,
  ) {
    return _combined([
      for (final item in selection)
        context.ownHosts(item.buildInspection(context.owners)),
    ]);
  }

  /// [contents] shown together: their bodies in order, then their hosts.
  InspectionContent _combined(List<InspectionContent> contents) {
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

  @override
  void dispose() {
    _buildContext?.dispose();
    owners.dispose();
    super.dispose();
  }
}

Map<Object, SharedInspectionSurface> _indexSurfaces(
  Iterable<SharedInspectionSurface> surfaces,
) {
  final indexed = <Object, SharedInspectionSurface>{};
  for (final surface in surfaces) {
    if (indexed.containsKey(surface.id)) {
      throw StateError("Shared inspection surface ids must be unique");
    }
    indexed[surface.id] = surface;
  }
  return indexed;
}

/// Restores a resource selection and its route without retaining an inspector.
///
/// Editor resources use this destination after the inspector graph is rebuilt
/// or closed. It observes route and selection state, but owns neither; closing
/// it releases only those listeners.
final class InspectorDestination extends WorkDestination {
  InspectorDestination({
    required this.container,
    required this.router,
    required this.path,
    required this.identity,
  }) {
    router.addListener(notifyListeners);
    _selection = container.listen(selectionProvider, (_, next) {
      _selected = next;
      notifyListeners();
    }, fireImmediately: true);
  }

  final ProviderContainer container;
  final NavigationRouter router;
  final String path;
  final Object identity;
  late final ProviderSubscription<List<SelectableIdentifier>> _selection;
  List<SelectableIdentifier> _selected = const [];

  @override
  bool get isCurrent =>
      !_selection.closed &&
      router.currentPath == path &&
      (identity is! SelectableIdentifier || _selected.contains(identity));

  /// Navigates to the saved route and selects the saved resource, if any.
  @override
  Future<void> open() async {
    if (_selection.closed) return;
    if (router.currentPath != path) await router.navigatePath(path);
    if (identity case final SelectableIdentifier selected) {
      container.read(selectionProvider.notifier).replace([selected]);
    }
  }

  @override
  void dispose() {
    router.removeListener(notifyListeners);
    _selection.close();
    super.dispose();
  }
}
