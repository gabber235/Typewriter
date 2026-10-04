part of "service_host_selectable_test.dart";

void _testResourceConnections() {
  test(
    "connection replacement preserves drafts and uses the new client",
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      final workspace = harness.container.read(localWorkControllerProvider);
      final repositories = harness.container.read(resourceRepositoriesProvider);
      final owners = EditorOwnerRegistry(workspace: workspace);
      addTearDown(owners.dispose);

      _buildInspection(harness, owners);
      final source = _identitySource(owners);
      expect(
        source.update(
          DataPath.root.field("name"),
          const StringValue("renamed"),
        ),
        isA<AppliedEditorMutation>(),
      );
      expect(
        source.value(DataPath.root.field("name")).valueOrNull,
        const StringValue("renamed"),
      );

      final replacement = FakeNatsClient();
      addTearDown(replacement.dispose);
      replacement
        ..registerHandler(
          "cloud.to.user.user1.organization.org1.services.watch",
          (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
            skir.WatchOrganizationServicesResponse.wrapList([
              harness.service.toSkir(),
            ]),
          ),
        )
        ..registerHandler(
          _updateSubject,
          (_) => skir.UpdateOrganizationServiceResponse.serializer.toBytes(
            skir.UpdateOrganizationServiceResponse.wrapSuccess(
              harness.service.copyWith(name: "renamed", revision: 2).toSkir(),
            ),
          ),
        );
      (harness.container.read(
        natsProvider.notifier,
      ) as _ReplaceableNats).connection = replacement;
      await harness.container.pump();

      expect(
        harness.container.read(localWorkControllerProvider),
        same(workspace),
      );
      expect(
        harness.container.read(resourceRepositoriesProvider),
        same(repositories),
      );
      expect(
        source.value(DataPath.root.field("name")).valueOrNull,
        const StringValue("renamed"),
      );
      expect(await source.flush(), isA<MutationSuccess>());
      expect(harness.nats.requests, isEmpty);
      expect(replacement.requests.map((request) => request.subject), [
        "cloud.to.user.user1.organization.org1.services.watch",
        _updateSubject,
      ]);
    },
  );
}
