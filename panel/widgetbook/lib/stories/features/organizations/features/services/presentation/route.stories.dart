import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";

@widgetbook.UseCase(name: "Default", type: ServicesPage)
Widget servicesPageUseCase(BuildContext context) {
  return servicesPageStory();
}

@widgetbook.UseCase(name: "Service inspector", type: ServicesPage)
Widget serviceInspectorUseCase(BuildContext context) {
  return serviceInspectorStory(width: _inspectorWidth(context));
}

Widget serviceInspectorStory({Service? service, double width = 360}) => FakeApp(
  child: _ServiceInspectorStory(service: service, width: width),
);

Widget servicesPageStory() {
  final scenario = completeTopologyScenario();
  return FakeApp(
    overrides: [
      organizationTopologyControllerProvider.overrideWith2(
        (_) => _StoryTopology(scenario.topology),
      ),
      canonicalOrganizationServicesProvider.overrideWith2(
        (_) => _StoryServices(scenario.services),
      ),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.fewItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: ServicesPage()),
  );
}

class _StoryServices extends CanonicalOrganizationServices {
  _StoryServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) =>
      Stream.value(services);
}

class _StoryTopology extends OrganizationTopologyController {
  _StoryTopology(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<OrganizationTopology> build(skir.RecordId organizationId) =>
      Stream.value(topology);
}

final class _ServiceInspectorStory extends StatefulWidget {
  const _ServiceInspectorStory({required this.width, this.service});

  final Service? service;
  final double width;

  @override
  State<_ServiceInspectorStory> createState() => _ServiceInspectorStoryState();
}

final class _ServiceInspectorStoryState extends State<_ServiceInspectorStory> {
  late final Service _service =
      widget.service ?? completeTopologyScenario().services.first;
  late final _StoryEditorSource _source = _StoryEditorSource(
    _service.editorSnapshot,
  );
  late final EditorSourcePresentationHost _host = _service
      .portablePresentationHost(connected: true, identityOwner: _source);

  @override
  void dispose() {
    _host.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: widget.width,
          child: PortablePresentationRenderer(host: _host),
        ),
      ),
    ),
  );
}

final class _StoryEditorSource extends ChangeNotifier implements EditorSource {
  _StoryEditorSource(this._snapshot)
    : _document = _snapshot.document,
      _value = _snapshot.document.confirmedValue;

  final EditorSnapshot _snapshot;
  EditorDocument _document;
  DataValue _value;
  bool _hasWork = false;

  @override
  EditorDocument get document => _document;

  @override
  TypeExpression get rootType => _document.rootType;

  @override
  TypeCatalog get typeCatalog => _document.typeCatalog;

  @override
  bool get readOnly => false;

  @override
  EditorCommitPolicy get commitPolicy => EditorCommitPolicy.applyResource;

  @override
  bool get hasWork => _hasWork;

  @override
  List<TypeDiagnostic> get draftDiagnostics => _snapshot.validateDraft(_value);

  @override
  EditorValue value(DataPath path) => _value.readEditorValue(path);

  @override
  EditorMutationResult validate(DataPath path, DataValue value) =>
      _snapshot.validate(path, value);

  @override
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    final accepted = validate(path, value);
    if (accepted is! AppliedEditorMutation) return accepted;
    final replaced = path.replace(_value, value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    _value = replaced.valueOrNull!;
    _hasWork = true;
    notifyListeners();
    return accepted;
  }

  @override
  EditorInteractionSession beginInteraction(DataPath path) =>
      _StoryServiceInteraction(this, path, value(path).valueOrNull);

  @override
  void discardDraft() {
    _value = _document.confirmedValue;
    _hasWork = false;
    notifyListeners();
  }

  @override
  void refreshDocument(EditorDocument document) {
    _document = document;
    _value = document.confirmedValue;
    _hasWork = false;
    notifyListeners();
  }

  @override
  EditorSaveState saveState(DataPath path) => const EditorSaveState.idle();

  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async {
    _document = _document.copyWith(
      revision: _document.revision + 1,
      confirmedValue: _value,
    );
    _hasWork = false;
    notifyListeners();
    return TypedMutationResult.success(
      revision: _document.revision,
      value: _value,
    );
  }

  @override
  void acceptRemote({required int revision, required DataValue value}) {
    refreshDocument(
      _document.copyWith(revision: revision, confirmedValue: value),
    );
  }

  @override
  void acceptRemoteDeletion() {}

  @override
  void useRemote(DataPath path) => discardDraft();

  @override
  Future<TypedMutationResult> keepLocal(DataPath path) => flush(paths: {path});
}

final class _StoryServiceInteraction implements EditorInteractionSession {
  _StoryServiceInteraction(this._source, this.path, this._origin);

  final _StoryEditorSource _source;
  final DataValue? _origin;

  @override
  final DataPath path;

  @override
  bool active = true;

  @override
  Future<void> commit() async {
    active = false;
  }

  @override
  void cancel() {
    if (!active) return;
    active = false;
    if (_origin case final value?) _source.update(path, value);
  }
}

@widgetbook.UseCase(name: "Host inspector", type: ServicesPage)
Widget hostInspectorUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  final index = context.knobs.int.slider(
    label: "Host scenario",
    initialValue: 0,
    min: 0,
    max: scenario.topology.hosts.length - 1,
  );
  return hostInspectorStory(
    host: scenario.topology.hosts[index],
    width: _inspectorWidth(context),
  );
}

double _inspectorWidth(BuildContext context) => context.knobs.double.slider(
  label: "Inspector width",
  initialValue: 360,
  min: 280,
  max: 700,
);

Widget hostInspectorStory({TopologyHost? host, double width = 360}) => FakeApp(
  child: _HostInspectorStory(
    key: ValueKey(host?.hostId),
    host: host,
    width: width,
  ),
);

final class _HostInspectorStory extends StatefulWidget {
  const _HostInspectorStory({required this.width, this.host, super.key});
  final TopologyHost? host;
  final double width;
  @override
  State<_HostInspectorStory> createState() => _HostInspectorStoryState();
}

final class _HostInspectorStoryState extends State<_HostInspectorStory> {
  late final _scenario = completeTopologyScenario();
  late final _hostValue = widget.host ?? _scenario.topology.hosts.first;
  late final _service = _scenario.services.firstWhere(
    (service) => service.serviceId == _hostValue.serviceId,
  );
  late final _configuration = _StoryEditorSource(
    HostEditorSnapshot(_hostValue, _scenario.topology),
  );
  late final _identity = _StoryEditorSource(_service.editorSnapshot);
  late final _host = topologyHostPortableHost(
    host: _hostValue,
    service: _service,
    connected: _hostValue.state.status != TopologyHostStatus.offline,
    configurationOwner: _configuration,
    identityOwner: _identity,
    realmTargets: const {
      "paper": ["^1"],
      "conformance": ["^1"],
    },
    engineTargets: {
      for (final engine in _hostValue.supportedEngines) engine.engineId: ["^1"],
    },
    realms: _scenario.topology.realmInstances
        .where((realm) => realm.ownerHost.id != _hostValue.hostId)
        .toList(),
  );
  @override
  void dispose() {
    _host.dispose();
    _configuration.dispose();
    _identity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: widget.width,
          child: PortablePresentationRenderer(host: _host),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Realm inspector", type: ServicesPage)
Widget realmInspectorUseCase(BuildContext context) {
  final realms = completeTopologyScenario().topology.realmInstances;
  final index = context.knobs.int.slider(
    label: "Realm scenario",
    initialValue: 0,
    min: 0,
    max: realms.length - 1,
  );
  return runtimeInspectorStory(
    host: realms[index].portablePresentationHost(),
    width: _inspectorWidth(context),
  );
}

@widgetbook.UseCase(name: "Engine inspector", type: ServicesPage)
Widget engineInspectorUseCase(BuildContext context) {
  final engines = completeTopologyScenario().topology.engineInstances;
  final index = context.knobs.int.slider(
    label: "Engine scenario",
    initialValue: 0,
    min: 0,
    max: engines.length - 1,
  );
  return runtimeInspectorStory(
    host: engines[index].portablePresentationHost(),
    width: _inspectorWidth(context),
  );
}

Widget runtimeInspectorStory({
  required EditorSourcePresentationHost host,
  double width = 360,
}) => FakeApp(
  child: _RuntimeInspectorStory(host: host, width: width),
);

final class _RuntimeInspectorStory extends StatefulWidget {
  const _RuntimeInspectorStory({required this.host, required this.width});
  final EditorSourcePresentationHost host;
  final double width;
  @override
  State<_RuntimeInspectorStory> createState() => _RuntimeInspectorStoryState();
}

final class _RuntimeInspectorStoryState extends State<_RuntimeInspectorStory> {
  @override
  void didUpdateWidget(covariant _RuntimeInspectorStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host != widget.host) oldWidget.host.dispose();
  }

  @override
  void dispose() {
    widget.host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: widget.width,
          child: PortablePresentationRenderer(host: widget.host),
        ),
      ),
    ),
  );
}
