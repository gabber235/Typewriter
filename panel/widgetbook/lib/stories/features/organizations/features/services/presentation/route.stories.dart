import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";

@widgetbook.UseCase(name: "Default", type: ServicesPage)
Widget servicesPageUseCase(BuildContext context) {
  return servicesPageStory();
}

@widgetbook.UseCase(name: "Service inspector", type: ServicesPage)
Widget serviceInspectorUseCase(BuildContext context) {
  return serviceInspectorStory();
}

Widget serviceInspectorStory({Service? service}) =>
    FakeApp(child: _ServiceInspectorStory(service: service));

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
  const _ServiceInspectorStory({this.service});

  final Service? service;

  @override
  State<_ServiceInspectorStory> createState() => _ServiceInspectorStoryState();
}

final class _ServiceInspectorStoryState extends State<_ServiceInspectorStory> {
  late final Service _service =
      widget.service ?? completeTopologyScenario().services.first;
  late final _StoryServiceSource _source = _StoryServiceSource(
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
          width: 640,
          child: PortablePresentationRenderer(host: _host),
        ),
      ),
    ),
  );
}

final class _StoryServiceSource extends ChangeNotifier implements EditorSource {
  _StoryServiceSource(this._snapshot)
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

  final _StoryServiceSource _source;
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
