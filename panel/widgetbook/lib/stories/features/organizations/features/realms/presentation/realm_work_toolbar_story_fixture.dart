import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

enum RealmWorkToolbarScenario {
  idle,
  active,
  blocked,
  interrupted,
  pendingDraft,
}

/// Real workspace and publication owners with external transport observations.
final class RealmWorkToolbarStoryFixture {
  RealmWorkToolbarStoryFixture(this.scenario) {
    final document = fixtureAuthoringDocument(
      pages: [
        Page(
          pageId: page,
          bookId: null,
          name: "Welcome",
          configuration: skir.TypeSelection.unknown,
          chapter: "Introduction",
          priority: 0,
        ),
        Page(
          pageId: otherPage,
          bookId: null,
          name: "Market",
          configuration: skir.TypeSelection.unknown,
          chapter: "Town",
          priority: 1,
        ),
      ],
    );
    transport = ScriptedAuthoringTransport(
      AsyncData(document),
      onRequest: (_) {
        final accepted = workspace.document;
        final index = transport.requests.length - 1;
        scheduleMicrotask(() => transport.confirm(index, accepted));
      },
    );
    workspace = AuthoringWorkspace(transport: transport, initial: document);
    repository = RealmWorkToolbarStoryRepository(this);
    if (scenario == RealmWorkToolbarScenario.pendingDraft) {
      workspace.edit(
        label: "Rename Welcome",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(
          nameLocation,
          skir.DataValue.wrapStringValue("Welcome to the town"),
        ),
      );
    }
  }

  final RealmWorkToolbarScenario scenario;
  final scope = AuthoringScope(
    organizationId: skir.recordId("organization:toolbar_story"),
    realmId: skir.recordId("service:toolbar_story"),
  );
  final page = skir.ResourceId(value: "page:welcome");
  final otherPage = skir.ResourceId(value: "page:market");
  late final ScriptedAuthoringTransport transport;
  late final AuthoringWorkspace workspace;
  late final RealmWorkToolbarStoryRepository repository;
  skir.ValueLocation get nameLocation => skir.ValueLocation(
    resource: page,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "name")],
    ),
  );
  String get workingName =>
      workspace.document.resource(page)!.authoredField("name")!.authoredString!;
  String get savedName => workspace.state.confirmed!
      .resource(page)!
      .authoredField("name")!
      .authoredString!;

  void dispose() {
    workspace.dispose();
    transport.dispose();
    unawaited(repository.close());
  }
}

final class RealmWorkToolbarStoryRepository
    implements RealmPublicationRepository {
  RealmWorkToolbarStoryRepository(this.fixture);
  final RealmWorkToolbarStoryFixture fixture;
  final publishedNames = <String>[];
  final _reports = StreamController<skir.PublicationReport>.broadcast();
  @override
  Stream<skir.PublicationReport> watch() async* {
    final state = switch (fixture.scenario) {
      RealmWorkToolbarScenario.active => skir.PublicationState.compiling,
      RealmWorkToolbarScenario.blocked => skir.PublicationState.wrapBlocked([
        _finding,
      ]),
      RealmWorkToolbarScenario.interrupted => skir.PublicationState.interrupted,
      _ => skir.PublicationState.complete,
    };
    yield skir.PublicationReport(
      id: skir.PublicationId(value: "publication:town"),
      state: state,
      findings: fixture.scenario == RealmWorkToolbarScenario.blocked
          ? [_finding]
          : [],
    );
    yield* _reports.stream;
  }

  @override
  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) async {
    final allRoots = [
      skir.CompilationRoot(
        projection: skir.CompilationProjectionId(value: "typewriter.page"),
        resource: fixture.page,
      ),
      skir.CompilationRoot(
        projection: skir.CompilationProjectionId(value: "typewriter.page"),
        resource: fixture.otherPage,
      ),
    ];
    final roots = switch (selection) {
      skir.CompilationStatusSelection_suppliedRootsWrapper(:final value) =>
        value,
      _ when selection == skir.CompilationStatusSelection.allRoots => allRoots,
      _ => const <skir.CompilationRoot>[],
    };
    return [
      for (final root in roots)
        skir.CompiledResourceStatus(
          root: root,
          state: root.resource == fixture.page
              ? skir.CompiledResourceState.wrapActive(
                  skir.PublicationId(value: "publication:town"),
                )
              : skir.CompiledResourceState.notCompiled,
        ),
    ];
  }

  @override
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish() =>
      PreparedCommit(
        id: Object(),
        label: "Publish saved content",
        replay: SubmissionReplay.unsupported,
        resources: {WorkDriverId(domain: "publication", scope: fixture.scope)},
        send: () async {
          publishedNames.add(fixture.savedName);
          _reports.add(
            skir.PublicationReport(
              id: skir.PublicationId(value: "publication:next"),
              state: skir.PublicationState.compiling,
              findings: [],
            ),
          );
          return SubmissionConfirmed(
            skir.PublishAuthoringResponse.wrapResult(
              skir.PublicationResult.publishing,
            ),
          );
        },
      );

  Future<void> close() => _reports.close();
  skir.Diagnostic get _finding => skir.Diagnostic(
    id: skir.DiagnosticId(value: "page:required_target"),
    origin: skir.RuleOrigin.defaultInstance,
    code: "required_target",
    message: "Market needs a dialogue target before publication",
    severity: skir.DiagnosticSeverity.error,
    primary: null,
    related: [],
  );
}
