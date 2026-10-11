part of "service_host_selectable_test.dart";

skir.DataValue _mode(
  String name, [
  Map<String, skir.DataValue> fields = const {},
]) {
  final type = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "panel.host", name: name),
    revision: 1,
  );
  return skir.DataValue.createNamed(
    actualType: skir.NamedTypeUse(definition: type, arguments: const []),
    payload: skir.DataValue.createRecord(
      fields: [
        for (final entry in fields.entries)
          skir.FieldValue(name: entry.key, value: entry.value),
      ],
    ),
  );
}

void _testHostApply() {
  test(
    "Host Realm and engine assignments remain a draft until complete Apply",
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);

      final owners = EditorOwnerRegistry();
      addTearDown(owners.dispose);
      _buildInspection(harness, owners);
      final owner = _configurationSource(owners);
      final path = editorRootPath.field("realm");
      final interaction = owner.beginInteraction(path);

      owner.update(
        path,
        _mode("RealmHosted", {"target": skir.DataValue.wrapStringValue("")}),
      );
      await interaction.commit();

      expect(
        harness.nats.requests.where(
          (request) => request.subject == _configureSubject,
        ),
        isEmpty,
      );
      expect(await owner.flush(), isA<MutationInvalid>());
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _configureSubject,
        ),
        isEmpty,
      );

      owner.update(
        path,
        _mode("RealmHosted", {
          "target": skir.DataValue.wrapStringValue("paper@*"),
        }),
      );
      expect(
        owner.update(
          editorRootPath.field("engine"),
          _mode("EngineEnabled", {
            "target": skir.DataValue.wrapStringValue("paper@*"),
            "realm": skir.DataValue.wrapStringValue("realm_instance:elsewhere"),
          }),
        ),
        isA<AppliedEditorMutation>(),
      );
      expect(owner.draftDiagnostics, isEmpty);
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _configureSubject,
        ),
        isEmpty,
      );
      skir.ConfigureServiceHostRequest? submitted;
      harness.respond(_configureSubject, (bytes) {
        submitted = skir.ConfigureServiceHostRequest.serializer.fromBytes(
          bytes,
        );
        return skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: _hostWithRevision(harness.host, 2),
            realm: harness.realm,
            engine: skir.EngineInstance(
              engineId: skir.recordId("engine_instance:paper"),
              ownerHost: harness.realm.ownerHost,
              realm: skir.RealmInfo(
                realmId: harness.realm.realmId,
                ownerHost: harness.realm.ownerHost,
              ),
              revision: 1,
              target: skir.EngineTarget(
                engineId: "paper",
                versionConstraint: "*",
              ),
              state: skir.ChildRuntimeState.defaultInstance,
            ),
            removedResources: [],
          ),
        );
      });

      expect(await owner.flush(), isA<MutationSuccess>());
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _configureSubject,
        ),
        hasLength(1),
      );
      expect(submitted!.execution.realm, isNotNull);
      expect(
        submitted!.execution.primaryEngine!.realm,
        skir.EngineRealmSelection.hostedRealm,
      );
      expect(owner.hasWork, isFalse);
    },
  );

  test("changing organization discards a retained Host draft", () async {
    var organization = _organizationId;
    final harness = await _Harness.create(organization: () => organization);
    addTearDown(harness.dispose);
    await harness.container.read(userIdProvider.future);
    final workspace = harness.container.read(localWorkControllerProvider);
    final view = EditorOwnerRegistry(workspace: workspace);

    _buildInspection(harness, view);
    final owner = _configurationSource(view)
      ..update(
        editorRootPath.field("realm"),
        _mode("RealmHosted", {
          "target": skir.DataValue.wrapStringValue("paper@*"),
        }),
      );
    view.dispose();
    harness.servicesSubscription.close();
    harness.topologySubscription.close();
    organization = skir.recordId("organization:org2");
    harness.container.invalidate(organizationIdProvider);

    await harness.container.pump();
    harness.respond(
      _configureSubject,
      (_) => skir.ConfigureServiceHostResponse.serializer.toBytes(
        skir.ConfigureServiceHostResponse.createSuccess(
          host: _hostWithRevision(harness.host, 2),
          realm: harness.realm,
          engine: null,
          removedResources: [],
        ),
      ),
    );
    expect(
      harness.container.read(localWorkControllerProvider),
      same(workspace),
    );
    expect(workspace.resources, isEmpty);
    expect(await owner.flush(), isA<MutationUnavailable>());
    expect(
      harness.nats.requests
          .where((request) => request.subject.endsWith(".topology.configure"))
          .map((request) => request.subject),
      isEmpty,
    );
  });

  test(
    "Host draft requires an existing Realm when Realm hosting is disabled",
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      final owners = EditorOwnerRegistry();
      addTearDown(owners.dispose);
      _buildInspection(harness, owners);
      final owner = _configurationSource(owners);
      expect(
        owner.update(
          editorRootPath.field("engine"),
          _mode("EngineEnabled", {
            "target": skir.DataValue.wrapStringValue("paper@*"),
            "realm": skir.DataValue.wrapStringValue(""),
          }),
        ),
        isA<AppliedEditorMutation>(),
      );

      expect(
        owner.draftDiagnostics.map((issue) => issue.path),
        contains(editorRootPath.field("engine").field("realm")),
      );
      expect(await owner.flush(), isA<MutationInvalid>());
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _configureSubject,
        ),
        isEmpty,
      );

      owner.update(
        editorRootPath.field("realm"),
        _mode("RealmHosted", {
          "target": skir.DataValue.wrapStringValue("paper@*"),
        }),
      );
      expect(owner.draftDiagnostics, isEmpty);
      owner.update(editorRootPath.field("realm"), _mode("RealmDisabled"));
      expect(await owner.flush(), isA<MutationInvalid>());
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _configureSubject,
        ),
        isEmpty,
      );
      owner.discardDraft();

      expect(owner.hasWork, isFalse);
    },
  );
}
