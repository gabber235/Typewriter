part of "service_host_selectable_test.dart";

void _testInspectorNameRefresh() {
  testWidgets("valid deletion keeps inspector focus before autosave", (
    tester,
  ) async {
    final harness = await _pumpNameInspector(tester);
    final session = harness.container.read(inspectionSessionProvider);
    final owner = _identitySource(session.owners);
    final selection = harness.container.read(selectionProvider);
    final before = tester.state<EditableTextState>(_nameEditable());
    expect(before.widget.focusNode.hasPrimaryFocus, isTrue);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "gabb",
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await _pumpInspectionRefresh(tester);

    final current = _identitySource(session.owners);
    expect(current.workspace, same(owner.workspace));
    expect(current.groupId, owner.groupId);
    expect(harness.container.read(inspectionSessionProvider), same(session));
    expect(harness.container.read(selectionProvider), selection);
    expect(_name(current), "gabb");
    expect(current.hasWork, isTrue);
    expect(_renameRequests(harness), isEmpty);
    expect(tester.takeException(), isNull);
    _expectRetainedNameInput(tester, before, "gabb", offset: 4);
    current.discardDraft();
    await tester.pump();
  });

  testWidgets("runtime observation keeps inspector focus without typing", (
    tester,
  ) async {
    final harness = await _pumpNameInspector(tester);
    final session = harness.container.read(inspectionSessionProvider);
    final owner = _identitySource(session.owners);
    final before = tester.state<EditableTextState>(_nameEditable());
    expect(before.widget.focusNode.hasPrimaryFocus, isTrue);

    _reportHostObservation(harness);
    await _pumpInspectionRefresh(tester);

    final current = _identitySource(session.owners);
    expect(current.workspace, same(owner.workspace));
    expect(current.groupId, owner.groupId);
    expect(_name(current), "gabbe");
    expect(current.document.revision, 1);
    expect(current.hasWork, isFalse);
    expect(_renameRequests(harness), isEmpty);
    expect(tester.takeException(), isNull);
    _expectRetainedNameInput(tester, before, "gabbe");
  });

  testWidgets("rejected name survives five idle seconds without observation", (
    tester,
  ) async {
    final harness = await _pumpNameInspector(tester);
    final before = tester.state<EditableTextState>(_nameEditable());

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "ga",
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    final owner = _identitySource(
      harness.container.read(inspectionSessionProvider).owners,
    );
    expect(_name(owner), "gabbe");
    expect(owner.hasWork, isFalse);
    expect(_renameRequests(harness), isEmpty);
    _expectRetainedNameInput(tester, before, "ga", offset: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets("runtime observation preserves a temporarily invalid name", (
    tester,
  ) async {
    final harness = await _pumpNameInspector(tester);
    final before = tester.state<EditableTextState>(_nameEditable());
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "ga",
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pumpAndSettle();
    _expectRetainedNameInput(tester, before, "ga", offset: 2);

    _reportHostObservation(harness);
    await _pumpInspectionRefresh(tester);

    expect(_renameRequests(harness), isEmpty);
    expect(tester.takeException(), isNull);
    _expectRetainedNameInput(tester, before, "ga", offset: 2);
    expect(
      find.text(
        "Use at least three lowercase letters or digits separated by underscores",
      ),
      findsOneWidget,
    );
  });

  test("valid service draft stages and reaches the save callback", () async {
    final service = _draftService();
    final snapshot = service.editorSnapshot;
    final commits = <EditorCommit>[];
    final owner = fakeValueEditing(
      document: snapshot.document,
      snapshot: snapshot,
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (commit) async {
        commits.add(commit);
        return MutationSuccess(revision: 2, value: commit.rootValue);
      },
    );
    addTearDown(owner.dispose);

    final result = owner.update(
      editorRootPath.field("name"),
      skir.DataValue.wrapStringValue("gabb"),
    );

    expect(result, isA<AppliedEditorMutation>());
    expect(_name(owner), "gabb");
    expect(owner.hasWork, isTrue);
    expect(await owner.flush(), isA<MutationSuccess>());
    expect(commits, hasLength(1));
    expect(
      commits.single.rootValue
          .editorValueAt(editorRootPath.field("name"))
          ?.authoredString,
      "gabb",
    );
  });

  test("invalid service name remains an unsaved attempt", () {
    final snapshot = _draftService().editorSnapshot;
    final owner = fakeValueEditing(
      document: snapshot.document,
      snapshot: snapshot,
      commitPolicy: EditorCommitPolicy.applyResource,
    );
    addTearDown(owner.dispose);

    final result = owner.update(
      editorRootPath.field("name"),
      skir.DataValue.wrapStringValue("ga"),
    );

    expect(result, isA<InvalidEditorMutation>());
    expect(_name(owner), "gabbe");
    expect(owner.hasWork, isFalse);
  });

  test("invalid service name blocks metadata commit", () {
    final service = _draftService();
    final proposed = ValueEditDocument(
      metadata: service.editorSnapshot,
      value: service.copyWith(name: "ga").identityValue,
      identity: service.serviceId,
    );

    expect(
      const ValueEditModel().validateCommit(proposed),
      isNotEmpty,
      reason: "Service metadata is saved only when valid",
    );
  });
}

Future<_Harness> _pumpNameInspector(WidgetTester tester) async {
  late _Harness harness;
  await tester.runAsync(() async {
    harness = await _Harness.create(serviceName: "gabbe");
    addTearDown(harness.dispose);
  });
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpTestApp(
    child: UncontrolledProviderScope(
      container: harness.container,
      child: const Material(child: DesktopInspector(child: SizedBox.expand())),
    ),
  );
  await tester.showKeyboard(find.byType(TextFormField).first);
  await tester.pumpAndSettle();
  return harness;
}

Future<void> _pumpInspectionRefresh(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump();
  }
}

void _reportHostObservation(_Harness harness) {
  final topology = harness.container
      .read(organizationTopologyProvider)
      .requireValue;
  final host = topology.hosts.single;
  (harness.container.read(
    organizationTopologyControllerProvider(_organizationId).notifier,
  ) as _SeededTopology).replace(
    topology.copyWith(
      hosts: [
        host.copyWith(
          state: host.state.copyWith(
            updatedAt: host.state.updatedAt.add(const Duration(seconds: 5)),
          ),
        ),
      ],
    ),
  );
}

void _expectRetainedNameInput(
  WidgetTester tester,
  EditableTextState before,
  String text, {
  int? offset,
}) {
  final after = tester.state<EditableTextState>(_nameEditable());
  expect(
    {
      "same editable state": identical(after, before),
      "same controller": identical(
        after.widget.controller,
        before.widget.controller,
      ),
      "same focus node": identical(
        after.widget.focusNode,
        before.widget.focusNode,
      ),
      "primary focus": after.widget.focusNode.hasPrimaryFocus,
      "typed name": after.widget.controller.text,
    },
    {
      "same editable state": true,
      "same controller": true,
      "same focus node": true,
      "primary focus": true,
      "typed name": text,
    },
    reason: "Refreshing the same selection must preserve its active editor",
  );
  if (offset != null) {
    expect(
      after.widget.controller.selection,
      TextSelection.collapsed(offset: offset),
    );
  }
}

String? _name(ValueEditing owner) {
  return owner.value(editorRootPath.field("name")).valueOrNull?.authoredString;
}

Iterable<Object> _renameRequests(_Harness harness) {
  return harness.nats.requests.where(
    (request) => request.subject == _updateSubject,
  );
}

Service _draftService() {
  return Service(
    serviceId: skir.recordId("service:draft_test"),
    revision: 1,
    name: "gabbe",
    role: HostServiceRole(version: "1.0.0"),
    createdAt: DateTime.utc(2026),
  );
}

Finder _nameEditable() {
  return find.descendant(
    of: find.byType(TextFormField).first,
    matching: find.byType(EditableText),
  );
}
