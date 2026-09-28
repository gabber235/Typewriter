part of "service_host_selectable_test.dart";

void _testHostTargetSelection() {
  for (final realmTarget in ["other", "paper"]) {
    testWidgets(
      "hosted Realm inference respects ${realmTarget == "paper" ? "version constraints" : "engine identity"}",
      (tester) async {
        final hosted = skir.RealmInstance(
          realmId: recordId("realm_instance:paper"),
          ownerHost: skir.OwnerHost(
            id: recordId("service_host:paper"),
            name: "Host",
          ),
          revision: 1,
          targetEngine: skir.EngineTarget(
            engineId: realmTarget,
            versionConstraint: "^1",
          ),
          state: skir.ChildRuntimeState.defaultInstance,
        );
        final external = skir.RealmInstance(
          realmId: recordId("realm_instance:external"),
          ownerHost: skir.OwnerHost(
            id: recordId("service_host:external"),
            name: "Compatible Realm",
          ),
          revision: 1,
          targetEngine: skir.EngineTarget(
            engineId: "paper",
            versionConstraint: "*",
          ),
          state: skir.ChildRuntimeState.defaultInstance,
        );
        final incompatible = skir.RealmInstance(
          revision: 1,
          state: skir.ChildRuntimeState.defaultInstance,
          realmId: recordId("realm_instance:incompatible"),
          ownerHost: skir.OwnerHost(
            id: recordId("service_host:incompatible"),
            name: "Incompatible Realm",
          ),
          targetEngine: skir.EngineTarget(
            engineId: "paper",
            versionConstraint: "^2",
          ),
        );

        final harness = (await tester.runAsync(
          () => _Harness.create(
            supportedEngineIds: ["paper", "other"],
            realms: [hosted, external, incompatible],
          ),
        ))!;
        addTearDown(harness.dispose);
        final owners = EditorOwnerRegistry();
        addTearDown(owners.dispose);

        final model = harness.selectable.buildPresentation(owners);
        final owner =
            (model.inputs[const BindingId(1)]! as PresentationEditInput).owner
                as EditorSource;
        expect(
          owner.update(
            DataPath.root.field("engine"),
            _mode("EngineEnabled", {
              "target": const StringValue("paper@*"),
              "realm": const StringValue(""),
            }),
          ),
          isA<AppliedEditorMutation>(),
        );
        await tester.pumpTestApp(
          child: SingleChildScrollView(child: ComposedEditor(model: model)),
        );

        expect(find.text("Assigned Realm"), findsOneWidget);
        expect(find.text("Compatible Realm"), findsWidgets);
        expect(find.text("Incompatible Realm"), findsNothing);
        expect(
          owner.value(DataPath.root.field("engine").field("realm")).valueOrNull,
          StringValue(external.realmId.id),
        );
        expect(owner.draftDiagnostics, isEmpty);
        skir.ConfigureServiceHostRequest? submitted;

        harness.respond(_configureSubject, (bytes) {
          submitted = skir.ConfigureServiceHostRequest.serializer.fromBytes(
            bytes,
          );
          return skir.ConfigureServiceHostResponse.serializer.toBytes(
            skir.ConfigureServiceHostResponse.createSuccess(
              removedResources: [],
              host: _hostWithRevision(harness.host, 2),
              realm: hosted,
              engine: skir.EngineInstance(
                engineId: recordId("engine_instance:paper"),
                ownerHost: hosted.ownerHost,
                realm: skir.RealmInfo(
                  realmId: external.realmId,
                  ownerHost: external.ownerHost,
                ),
                revision: 1,
                target: external.targetEngine,
                state: skir.ChildRuntimeState.defaultInstance,
              ),
            ),
          );
        });
        expect(await tester.runAsync(owner.flush), isA<MutationSuccess>());
        await tester.pumpAndSettle();
        expect(
          submitted!.execution.primaryEngine!.realm,
          skir.EngineRealmSelection.createExistingRealm(
            realmId: external.realmId,
          ),
        );
        expect(
          owner.update(
            DataPath.root.field("engine"),
            _mode("EngineEnabled", {
              "target": const StringValue("paper@*"),
              "realm": StringValue(incompatible.realmId.id),
            }),
          ),
          isA<AppliedEditorMutation>(),
        );
        expect(owner.draftDiagnostics, isNotEmpty);

        owner.update(
          DataPath.root.field("realm"),
          _mode("RealmHosted", {"target": const StringValue("paper@*")}),
        );
        await tester.pumpAndSettle();
        expect(find.text("Assigned Realm"), findsNothing);
        expect(owner.draftDiagnostics, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
