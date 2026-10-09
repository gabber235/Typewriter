import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "publication toolbar shows saved Page status and blocked findings while a rename stays local",
    (tester) async {
      final source = _document();
      final second = skir.ResourceId(value: "second");
      final document = source.copyWith(
        entries: {
          _resource: skir.AuthoringResource(
            id: _resource,
            definition: corePageResourceDefinition,
            content: source.resource(_resource)!,
          ),
          second: skir.AuthoringResource(
            id: second,
            definition: corePageResourceDefinition,
            content: skir.AuthoringRecord(
              configuration: skir.TypeSelection.unknown,
              fields: [
                skir.FieldValue(name: "name", value: _text("Other saved Page")),
              ],
            ),
          ),
        },
      );
      final workspace = AuthoringWorkspace(
        transport: _Transport(document),
        initial: document,
      );
      addTearDown(workspace.dispose);
      workspace.edit(
        label: "Rename",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(_name, _text("Pending rename")),
      );
      final repository = _WorkPublicationRepository(
        () => _read(workspace.state.confirmed!, _name),
      );
      addTearDown(repository.close);
      repository.statuses = [
        skir.CompiledResourceStatus(
          root: skir.CompilationRoot(
            projection: skir.CompilationProjectionId(value: "typewriter.page"),
            resource: _resource,
          ),
          state: skir.CompiledResourceState.wrapActive(
            skir.PublicationId(value: "selected"),
          ),
        ),
        skir.CompiledResourceStatus(
          root: skir.CompilationRoot(
            projection: skir.CompilationProjectionId(value: "typewriter.page"),
            resource: second,
          ),
          state: skir.CompiledResourceState.notCompiled,
        ),
      ];
      await tester.pumpTestApp(
        child: Scaffold(
          body: RealmWorkToolbar(workspace: workspace, scope: _workScope),
        ),
        overrides: [
          localWorkScopeProvider.overrideWithValue(
            LocalWorkScope(
              userId: "fixture",
              organizationId: _workScope.organizationId,
            ),
          ),
          realmPublicationRepositoryProvider(
            _workScope.organizationId,
            _workScope.realmId,
          ).overrideWithValue(repository),
        ],
      );
      expect(repository.queriedRoots.single.map((root) => root.resource), [
        _resource,
        second,
      ]);
      await tester.tap(find.text("Saved Page publication status (2 Pages)"));
      await tester.pumpAndSettle();
      expect(find.text("Original: Last published in selected"), findsOneWidget);
      expect(
        find.text("Other saved Page: Not in the selected publication"),
        findsOneWidget,
      );
      expect(find.textContaining("Pending rename:"), findsNothing);
      final diagnostic = skir.Diagnostic(
        id: skir.DiagnosticId(value: "missing"),
        origin: skir.RuleOrigin.defaultInstance,
        code: "required",
        message: "A required Page value is missing",
        severity: skir.DiagnosticSeverity.error,
        primary: null,
        related: [],
      );
      repository.reports.add(
        skir.PublicationReport(
          id: skir.PublicationId(value: "blocked"),
          findings: [diagnostic],
          state: skir.PublicationState.wrapBlocked([diagnostic]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text("Publication findings (1)"));
      await tester.pumpAndSettle();
      expect(find.text("A required Page value is missing"), findsOneWidget);
      await tester.tap(find.text("Publish saved content"));
      await tester.pumpAndSettle();
      expect(repository.publishedValues, [_text("Original")]);
      expect(_read(workspace.document, _name), _text("Pending rename"));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test("publication journal observation survives view release and distinguishes sending from uncertainty", () async {
    final work = ScopedWorkSession();
    addTearDown(work.dispose);
    final repository = _WorkPublicationRepository(() => _text("Saved"));
    addTearDown(repository.close);
    final gate = Completer<void>();
    repository.sendGate = gate;
    final driver = PublicationWorkDriver(_workScope, repository, work)..start();
    work.register(driver);
    final lease = work.lease(driver.id);
    var changes = 0;
    driver.addListener(() => changes++);
    final publishing = driver.publish();
    await Future<void>.delayed(Duration.zero);
    final sending = work.state.entries.values.single;
    expect(sending.saving, isTrue);
    expect(sending.needsAttention, isFalse);
    expect(
      sending.details.any(
        (fact) => fact.value == "Sending publication request",
      ),
      isTrue,
    );
    lease.release();
    repository.reports.add(
      skir.PublicationReport(
        id: skir.PublicationId(value: "active"),
        findings: [],
        state: skir.PublicationState.checking,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    expect(await publishing, skir.PublicationResult.publishing);
    await Future<void>.delayed(Duration.zero);
    expect(work.state.entries.values.single.phase, "Checking saved content");
    repository.reports.add(
      skir.PublicationReport(
        id: skir.PublicationId(value: "active"),
        findings: [],
        state: skir.PublicationState.compiling,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(work.state.entries.values.single.phase, "Compiling saved content");
    expect(changes, lessThan(10));
    expect(repository.publishedValues, hasLength(1));
    expect(work.state.blocksNavigation, isFalse);
  });

  test("graph work survives route release and closes after discard", () async {
    final workspace = AuthoringWorkspace(
      transport: _Transport(_document()),
      initial: _document(),
    );
    final work = ScopedWorkSession();
    addTearDown(work.dispose);
    final driver = AuthoringWorkDriver(_workScope, workspace);
    work.register(driver);
    final lease = work.lease(driver.id);
    final staged = workspace.edit(
      label: "Rename",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) => edit.set(_name, _text("Retained")),
    ) as AuthoringEditStaged;
    lease.release();
    await Future<void>.delayed(Duration.zero);
    expect(work.state.entries.values.single.label, "Rename");
    expect(work.state.blocksNavigation, isTrue);
    final entry = WorkEntryId(driver: driver.id, identity: staged.group);
    expect(work.discard(entry), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(work.state.entries, isEmpty);
    expect(() => work.lease(driver.id), throwsStateError);
  });

  test("preparation is visible before any graph operation exists", () async {
    final workspace = AuthoringWorkspace(
      transport: _Transport(_document()),
      initial: _document(),
    );
    final work = ScopedWorkSession();
    addTearDown(work.dispose);
    final driver = AuthoringWorkDriver(_workScope, workspace);
    work.register(driver);
    final lease = work.lease(driver.id);
    final gate = Completer<void>();
    final preparing = workspace.prepare(
      label: "Prepare rename",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) async {
        await gate.future;
        edit.set(_name, _text("Prepared"));
      },
    );
    expect(workspace.state.groups, isEmpty);
    expect(work.state.entries.values.single.phase, "Preparing changes");
    expect(work.state.blocksNavigation, isTrue);
    lease.release();
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    expect(await preparing, isA<AuthoringEditStaged>());
    expect(work.state.entries.values.single.label, "Prepare rename");
    expect(_read(workspace.document, _name), _text("Prepared"));
  });

  test(
    "publishing saved content leaves a pending rename and its work intact",
    () async {
      final workspace = AuthoringWorkspace(
        transport: _Transport(_document()),
        initial: _document(),
      );
      final work = ScopedWorkSession();
      addTearDown(work.dispose);
      final graph = AuthoringWorkDriver(_workScope, workspace);
      work.register(graph);
      final repository = _WorkPublicationRepository(
        () => _read(workspace.state.confirmed!, _name),
      );
      final publication = PublicationWorkDriver(_workScope, repository, work)
        ..start();
      work.register(publication);
      addTearDown(repository.close);
      workspace.edit(
        label: "Pending rename",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(_name, _text("Draft name")),
      );
      final before = workspace.state;
      expect(await publication.publish(), skir.PublicationResult.publishing);
      expect(repository.publishedValues, [_text("Original")]);
      expect(workspace.state, same(before));
      expect(_read(workspace.document, _name), _text("Draft name"));
      expect(
        work.state.entries.values.any(
          (entry) => entry.label == "Pending rename",
        ),
        isTrue,
      );
      expect(work.state.blocksNavigation, isTrue);
      expect(publication.snapshot.entries.single.blocksNavigation, isFalse);
    },
  );

  test("uncertain publication retains activity without offering replay or draft commands", () async {
    final work = ScopedWorkSession();
    addTearDown(work.dispose);
    final repository = _WorkPublicationRepository(() => _text("Saved"))
      ..uncertain = true;
    addTearDown(repository.close);
    final driver = PublicationWorkDriver(_workScope, repository, work)..start();
    work.register(driver);
    final lease = work.lease(driver.id);
    await expectLater(
      driver.publish(),
      throwsA(isA<SubmissionException<skir.PublishAuthoringResponse>>()),
    );
    lease.release();
    await Future<void>.delayed(Duration.zero);
    final entry = work.state.entries.values.single;
    expect(entry.needsAttention, isTrue);
    expect(entry.saving, isFalse);
    expect(entry.blocksNavigation, isFalse);
    expect(entry.canRetry || entry.canSave || entry.canDiscard, isFalse);
    expect(work.submissions.single.canReplay, isFalse);
    expect(driver.canPublish, isFalse);
    expect(await driver.publish(), skir.PublicationResult.publishing);
    expect(repository.publishedValues, hasLength(1));
    expect(work.state.blocksNavigation, isFalse);
  });

  test("two views share changes and detach retains their work", () {
    final transport = _Transport(_document());
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.current,
    );
    addTearDown(workspace.dispose);
    final first = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    final second = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(second.detach);
    first.edit(
      label: "Rename",
      apply: (edit) => edit.set(_name, _text("Local")),
    );
    expect(
      second.document.read(_name),
      const TypeMatcher<PortablePathValue<skir.DataValue>>(),
    );
    expect(_read(second.document, _name), _text("Local"));
    expect(second.dirty, isTrue);
    first.detach();
    expect(_read(workspace.document, _name), _text("Local"));
    second.discard();
    expect(_read(workspace.document, _name), _text("Original"));
    expect(transport.requests, isEmpty);
  });

  test(
    "independent placement save excludes pending name and survives discard",
    () async {
      final transport = _Transport(_document());
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.current,
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Rename",
        apply: (edit) => edit.set(_name, _text("Local")),
      );
      final moved = workspace.edit(
        label: "Move",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(_position, _text("50")),
      ) as AuthoringEditStaged;
      final saving = workspace.save(moved.group);
      await Future<void>.delayed(Duration.zero);
      expect(transport.requests, hasLength(1));
      expect(transport.requests.single.intents, hasLength(1));
      expect(
        (transport.requests.single.intents.single
                as skir.EditIntent_setValueWrapper)
            .value
            .at,
        _position,
      );
      transport
        ..current = _document(position: "50")
        ..reply.complete(
          skir.CommitPreparedEditResponse.wrapResult(
            skir.CommitResult.committed,
          ),
        );
      await saving;
      expect(_read(workspace.document, _name), _text("Local"));
      expect(_read(workspace.document, _position), _text("50"));
      form.discard();
      expect(_read(workspace.document, _name), _text("Original"));
      expect(_read(workspace.document, _position), _text("50"));
    },
  );

  test(
    "overlapping change waits without applying manual predecessor",
    () async {
      final transport = _Transport(_document());
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.current,
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Rename",
        apply: (edit) => edit.set(_name, _text("Local")),
      );
      final second = workspace.edit(
        label: "Rename again",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(_name, _text("Next")),
      ) as AuthoringEditStaged;
      expect(
        workspace.state.groups[second.group]!.phase,
        isA<AuthoringGroupAwaitingDependency>(),
      );
      await workspace.save(second.group);
      expect(transport.requests, isEmpty);
      form.discard();
      expect(
        workspace.state.groups[second.group]!.phase,
        isA<AuthoringGroupConflict>(),
      );
      expect(_read(workspace.document, _name), _text("Next"));
    },
  );

  test("failed primitive rejects the whole operation", () {
    final transport = _Transport(_document());
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.current,
    );
    addTearDown(workspace.dispose);
    final result = workspace.edit(
      label: "Invalid batch",
      apply: (edit) {
        edit
          ..set(_name, _text("Local"))
          ..set(
            skir.ValueLocation(
              resource: skir.ResourceId(value: "absent"),
              path: _name.path,
            ),
            _text("Bad"),
          );
      },
    );
    expect(result, isA<AuthoringEditRejected>());
    expect(workspace.state.groups, isEmpty);
    expect(_read(workspace.document, _name), _text("Original"));
  });

  test("editing while saving retains only the later operation", () async {
    final transport = _Transport(_document());
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.current,
    );
    addTearDown(workspace.dispose);
    final form = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(form.detach);
    form.edit(
      label: "Rename",
      apply: (edit) => edit.set(_name, _text("First")),
    );
    final saving = form.save();
    await Future<void>.delayed(Duration.zero);
    form.edit(
      label: "Continue",
      apply: (edit) => edit.set(_name, _text("Second")),
    );
    transport
      ..current = _document(name: "First")
      ..reply.complete(
        skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
      );
    await saving;
    expect(_read(workspace.document, _name), _text("Second"));
    expect(workspace.state.groups[form.editingGroup]!.operationCount, 1);
    expect(form.blocked, isFalse);
  });

  test("uncertain sends retain their frozen work and never replay", () async {
    final transport = _Transport(_document());
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.current,
    );
    addTearDown(workspace.dispose);
    final form = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(form.detach);
    form.edit(
      label: "Rename",
      apply: (edit) => edit.set(_name, _text("Local")),
    );
    final saving = form.save();
    await Future<void>.delayed(Duration.zero);
    transport.reply.completeError(StateError("Connection lost"));
    await saving;
    expect(form.phase, isA<AuthoringGroupUncertain>());
    expect(form.discard(), isFalse);
    await form.save();
    expect(transport.requests, hasLength(1));
  });
  for (final uncertain in [false, true]) {
    test(
      "discarding a later unsent edit preserves the ${uncertain ? 'uncertain' : 'committed'} prefix",
      () async {
        final transport = _Transport(_document())
          ..refreshFailure = StateError("Refresh unavailable");
        final workspace = AuthoringWorkspace(
          transport: transport,
          initial: transport.current,
        );
        addTearDown(workspace.dispose);
        final binding = workspace.attach(
          _resource,
          policy: EditorCommitPolicy.applyResource,
        );
        addTearDown(binding.detach);
        binding.edit(
          label: "First",
          apply: (edit) => edit.set(_name, _text("First")),
        );
        final saving = binding.save();
        await Future<void>.delayed(Duration.zero);
        binding.edit(
          label: "Later",
          apply: (edit) => edit.set(_name, _text("Later")),
        );
        if (uncertain) {
          transport.reply.completeError(StateError("Reply lost"));
        } else {
          transport.reply.complete(
            skir.CommitPreparedEditResponse.wrapResult(
              skir.CommitResult.committed,
            ),
          );
        }
        await saving;
        final phase = binding.phase;
        expect(binding.canDiscard, isTrue);
        expect(binding.discard(), isTrue);
        expect(binding.phase, phase);
        expect(binding.hasSubmittedWork, isTrue);
        expect(_read(binding.document, _name), _text("First"));
        expect(workspace.state.groups[binding.editingGroup]!.operationCount, 1);
        expect(binding.canDiscard, isFalse);
        expect(binding.discard(), isFalse);
        await binding.save();
        expect(transport.requests, hasLength(1));
      },
    );
  }

  test("display reads do not enroll facts or mutate an immutable revision", () {
    final transport = _Transport(_document());
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: transport.current,
    );
    addTearDown(workspace.dispose);
    final old = workspace.document
      ..read(_name)
      ..read(_position);
    expect(workspace.state.groups, isEmpty);
    final edit = AuthoringEdit.fromDocument(old)
      ..read(_position)
      ..set(_name, _text("Next"));
    expect(
      edit.expectations.whereType<skir.EditExpectation_valueWrapper>().map(
        (fact) => fact.value.at,
      ),
      [_name],
    );
    workspace.edit(
      label: "Rename",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) => edit.set(_name, _text("Next")),
    );
    expect(_read(old, _name), _text("Original"));
    expect(
      workspace.document.entry(_resource)!.definition,
      old.entry(_resource)!.definition,
    );
  });

  test("a failed operation with no intents is rejected", () {
    final workspace = AuthoringWorkspace(
      transport: _Transport(_document()),
      initial: _document(),
    );
    addTearDown(workspace.dispose);
    final result = workspace.edit(
      label: "Missing",
      apply: (edit) => edit.set(
        authoredFieldLocation(skir.ResourceId(value: "absent"), ["name"]),
        _text("Next"),
      ),
    );
    expect(result, isA<AuthoringEditRejected>());
    expect(workspace.state.groups, isEmpty);
  });

  test(
    "catalog changes retain pending values and block every preparation",
    () async {
      final transport = _Transport(_document());
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.current,
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Rename",
        apply: (edit) => edit.set(_name, _text("Local")),
      );
      final changed = _document().copyWith(
        catalog: authoringFixtureCatalog(
          generation: skir.CatalogGeneration(value: "next"),
        ),
      );
      workspace.acceptConfirmed(changed);
      expect(form.phase, isA<AuthoringGroupCatalogChanged>());
      expect(_read(form.document, _name), _text("Local"));
      expect(
        await workspace.prepare(
          label: "New",
          apply: (edit) async => edit.set(_position, _text("50")),
        ),
        isA<AuthoringEditRejected>(),
      );
      form.discard();
      expect(workspace.document.generation, changed.generation);
    },
  );

  test(
    "unrelated remote changes merge while guarded changes retain a conflict",
    () {
      final workspace = AuthoringWorkspace(
        transport: _Transport(_document()),
        initial: _document(),
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Rename",
        apply: (edit) => edit.set(_name, _text("Local")),
      );
      workspace.acceptConfirmed(_document(position: "Remote"));
      expect(form.blocked, isFalse);
      expect(_read(workspace.document, _position), _text("Remote"));
      workspace.acceptConfirmed(_document(name: "Remote", position: "Remote"));
      expect(form.phase, isA<AuthoringGroupConflict>());
      expect(_read(workspace.document, _name), _text("Local"));
      form.discard();
      expect(_read(workspace.document, _name), _text("Remote"));
    },
  );

  test(
    "delayed preparation rejects changed facts but accepts unrelated changes",
    () async {
      final workspace = AuthoringWorkspace(
        transport: _Transport(_document()),
        initial: _document(),
      );
      addTearDown(workspace.dispose);
      for (final changedName in [false, true]) {
        final gate = Completer<void>();
        final pending = workspace.prepare(
          label: "Prepared rename",
          policy: EditorCommitPolicy.applyResource,
          apply: (edit) async {
            edit.expect(_name);
            await gate.future;
            edit.set(_name, _text("Prepared"));
          },
        );
        workspace.acceptConfirmed(
          _document(
            name: changedName ? "Remote" : "Original",
            position: "Remote",
          ),
        );
        gate.complete();
        final result = await pending;
        expect(
          result,
          changedName
              ? isA<AuthoringEditRejected>()
              : isA<AuthoringEditStaged>(),
        );
        if (result is AuthoringEditStaged) workspace.discard(result.group);
      }
    },
  );

  test("closing a binding cancels delayed publication without discarding prior work", () async {
    final workspace = AuthoringWorkspace(
      transport: _Transport(_document()),
      initial: _document(),
    );
    addTearDown(workspace.dispose);
    final binding =
        workspace.attach(_resource, policy: EditorCommitPolicy.applyResource)
          ..edit(
            label: "Prior",
            apply: (edit) => edit.set(_position, _text("Prior")),
          );
    final gate = Completer<void>();
    final pending = binding.prepare(
      label: "Delayed",
      apply: (edit) async {
        edit.expect(_name);
        await gate.future;
        edit.set(_name, _text("Delayed"));
      },
    );
    binding.detach();
    gate.complete();
    expect(await pending, isA<AuthoringEditRejected>());
    expect(_read(workspace.document, _name), _text("Original"));
    expect(_read(workspace.document, _position), _text("Prior"));
  });

  test(
    "a known committed prefix refreshes without replaying and retains its tail",
    () async {
      final transport = _Transport(_document())
        ..refreshFailure = StateError("Refresh lost");
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.current,
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "First",
        apply: (edit) => edit.set(_name, _text("First")),
      );
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      form.edit(label: "Tail", apply: (edit) => edit.set(_name, _text("Tail")));
      transport.reply.complete(
        skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
      );
      await saving;
      expect(form.phase, isA<AuthoringGroupCommittedAwaitingRefresh>());
      expect(form.canDiscard, isTrue);
      transport
        ..refreshFailure = null
        ..current = _document(name: "First");
      await workspace.refreshConfirmed();
      expect(transport.requests, hasLength(1));
      expect(workspace.state.groups[form.editingGroup]!.operationCount, 1);
      expect(_read(workspace.document, _name), _text("Tail"));
      expect(form.blocked, isFalse);
    },
  );

  test(
    "the lane orders independent groups and excludes unrelated form work",
    () async {
      final transport = _Transport(_document());
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.current,
      );
      addTearDown(workspace.dispose);
      final first = workspace.edit(
        label: "Name",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(_name, _text("First")),
      ) as AuthoringEditStaged;
      final second = workspace.edit(
        label: "Position",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.set(_position, _text("Second")),
      ) as AuthoringEditStaged;
      final saving = workspace.save(first.group);
      await Future<void>.delayed(Duration.zero);
      unawaited(workspace.save(second.group));
      expect(transport.requests, hasLength(1));
      transport
        ..current = _document(name: "First")
        ..reply.complete(
          skir.CommitPreparedEditResponse.wrapResult(
            skir.CommitResult.committed,
          ),
        );
      await Future<void>.delayed(Duration.zero);
      expect(transport.requests, hasLength(2));
      expect(transport.requests.last.intents, hasLength(1));
      transport
        ..current = _document(name: "First", position: "Second")
        ..reply.complete(
          skir.CommitPreparedEditResponse.wrapResult(
            skir.CommitResult.committed,
          ),
        );
      await saving;
      expect(workspace.state.groups, isEmpty);
    },
  );

  test(
    "rejected saves retain their proposal without an automatic retry",
    () async {
      final transport = _Transport(_document());
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.current,
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Rename",
        apply: (edit) => edit.set(_name, _text("Local")),
      );
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      transport.reply.complete(
        skir.CommitPreparedEditResponse.wrapResult(
          skir.CommitResult.wrapConflict(const []),
        ),
      );
      await saving;
      await form.save();
      expect(form.phase, isA<AuthoringGroupConflict>());
      expect(_read(form.document, _name), _text("Local"));
      expect(transport.requests, hasLength(1));
      expect(form.discard(), isTrue);
    },
  );

  test("missing resources retain their proposal for comparison", () {
    final workspace = AuthoringWorkspace(
      transport: _Transport(_document()),
      initial: _document(),
    );
    addTearDown(workspace.dispose);
    final form = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(form.detach);
    form.edit(
      label: "Rename",
      apply: (edit) => edit.set(_name, _text("Retained")),
    );
    workspace.acceptConfirmed(_document().copyWith(entries: const {}));
    final phase = form.phase! as AuthoringGroupResourceMissing;
    expect(_read(phase.proposal, _name), _text("Retained"));
    expect(form.discard(), isTrue);
    expect(workspace.state.groups, isEmpty);
  });

  test(
    "record field order is irrelevant but collection item order is guarded",
    () {
      final document = _document();
      final workspace = AuthoringWorkspace(
        transport: _Transport(document),
        initial: document,
      );
      addTearDown(workspace.dispose);
      final form = workspace.attach(
        _resource,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      final root = skir.ValueLocation(
        resource: _resource,
        path: skir.ValuePath(segments: const []),
      );
      form.edit(
        label: "Guard record",
        apply: (edit) {
          edit
            ..expect(root)
            ..set(_position, _text("Next"));
        },
      );
      final entry = document.entry(_resource)!;
      workspace.acceptConfirmed(
        document.copyWith(
          entries: {
            _resource: skir.AuthoringResource(
              id: _resource,
              definition: entry.definition,
              content: skir.AuthoringRecord(
                configuration: entry.content.configuration,
                fields: entry.content.fields.toList().reversed,
              ),
            ),
          },
        ),
      );
      expect(form.blocked, isFalse);
      form.discard();
      final itemsAt = authoredFieldLocation(_resource, ["items"]);
      skir.DataValue items(List<String> ids) => skir.DataValue.createListValue(
        items: ids.map(
          (id) => skir.ListItem(
            id: skir.ItemId(value: id),
            value: _text(id),
          ),
        ),
      );
      final prepared = AuthoringEdit.fromDocument(document)
        ..set(itemsAt, items(["first", "second"]));
      workspace.acceptConfirmed(prepared.toDocument());
      form.edit(
        label: "Guard collection",
        apply: (edit) {
          edit
            ..expect(itemsAt)
            ..set(_position, _text("Next"));
        },
      );
      final remote = AuthoringEdit.fromDocument(prepared.toDocument())
        ..set(itemsAt, items(["second", "first"]));
      workspace.acceptConfirmed(remote.toDocument());
      expect(form.phase, isA<AuthoringGroupConflict>());
    },
  );

  test(
    "real providers isolate realms and retain unsent work without a view",
    () async {
      final container = ProviderContainer.test(
        overrides: [
          localWorkScopeProvider.overrideWithValue(
            LocalWorkScope(
              userId: "fixture",
              organizationId: skir.recordId("organization:test"),
            ),
          ),
          confirmedAuthoringDocumentProvider.overrideWith(
            (ref, scope) => AsyncData(_document()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final scope = AuthoringScope(
        organizationId: skir.recordId("organization:test"),
        realmId: skir.recordId("realm:first"),
      );
      final other = scope.copyWith(realmId: skir.recordId("realm:second"));
      final view = container.listen(
        authoringWorkspaceProvider(scope),
        (_, _) {},
      );
      final workspace = view.read();
      workspace.attach(_resource, policy: EditorCommitPolicy.applyResource)
        ..edit(
          label: "Rename",
          apply: (edit) => edit.set(_name, _text("Local")),
        )
        ..detach();
      view.close();
      await container.pump();
      expect(
        container.read(authoringWorkspaceProvider(scope)),
        same(workspace),
      );
      expect(
        _read(
          container.read(workingAuthoringDocumentProvider(other)).requireValue,
          _name,
        ),
        _text("Original"),
      );
      expect(
        _read(
          container.read(workingAuthoringDocumentProvider(scope)).requireValue,
          _name,
        ),
        _text("Local"),
      );
    },
  );
}

final _resource = skir.ResourceId(value: "resource");
final _name = skir.ValueLocation(
  resource: _resource,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "name")]),
);
final _position = skir.ValueLocation(
  resource: _resource,
  path: skir.ValuePath(
    segments: [skir.PathSegment.createField(name: "position")],
  ),
);
skir.DataValue _text(String value) => skir.DataValue.wrapStringValue(value);
skir.DataValue _read(AuthoringDocument document, skir.ValueLocation at) =>
    (document.read(at) as PortablePathValue<skir.DataValue>).value;
AuthoringDocument _document({
  String name = "Original",
  String position = "0",
}) => AuthoringDocument(
  catalog: CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: "fixture"),
      types: const [],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  ),
  entries: {
    _resource: skir.AuthoringResource(
      id: _resource,
      definition: skir.ResourceDefinitionId(value: "fixture.resource"),
      content: skir.AuthoringRecord(
        configuration: skir.TypeSelection.unknown,
        fields: [
          skir.FieldValue(name: "name", value: _text(name)),
          skir.FieldValue(name: "position", value: _text(position)),
        ],
      ),
    ),
  },
  links: const [],
);

final class _Transport implements AuthoringWorkspaceTransport {
  _Transport(this.current);
  AuthoringDocument current;
  final requests = <skir.PreparedEdit>[];
  final replies = <Completer<skir.CommitPreparedEditResponse>>[];
  Completer<skir.CommitPreparedEditResponse> get reply => replies.last;
  Error? refreshFailure;
  @override
  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) {
    requests.add(edit);
    final next = Completer<skir.CommitPreparedEditResponse>();
    replies.add(next);
    return next.future;
  }

  @override
  Future<AuthoringDocument> fetchConfirmed() async {
    if (refreshFailure case final error?) throw error;
    return current;
  }
}

final _workScope = AuthoringScope(
  organizationId: skir.recordId("organization:fixture"),
  realmId: skir.recordId("service:fixture"),
);

final class _WorkPublicationRepository implements RealmPublicationRepository {
  _WorkPublicationRepository(this.saved);
  final skir.DataValue Function() saved;
  final publishedValues = <skir.DataValue>[];
  final reports = StreamController<skir.PublicationReport>.broadcast();
  final queriedRoots = <List<skir.CompilationRoot>>[];
  List<skir.CompiledResourceStatus> statuses = [];
  bool uncertain = false;
  Completer<void>? sendGate;
  @override
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish() =>
      PreparedCommit(
        id: Object(),
        label: "Publish saved content",
        resources: {WorkDriverId(domain: "publication", scope: _workScope)},
        replay: SubmissionReplay.unsupported,
        send: () async {
          publishedValues.add(saved());
          if (sendGate case final gate?) await gate.future;
          if (uncertain) {
            return SubmissionUncertain(
              message: "Unknown delivery outcome",
              cause: StateError("Missing reply"),
              stackTrace: StackTrace.current,
            );
          }
          return SubmissionConfirmed(
            skir.PublishAuthoringResponse.wrapResult(
              skir.PublicationResult.publishing,
            ),
          );
        },
      );
  @override
  Future<List<skir.CompiledResourceStatus>> states(
    List<skir.CompilationRoot> roots,
  ) async {
    queriedRoots.add(List.unmodifiable(roots));
    return statuses;
  }

  @override
  Stream<skir.PublicationReport> watch() => reports.stream;
  Future<void> close() => reports.close();
}
