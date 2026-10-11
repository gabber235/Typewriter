import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  testWidgets(
    "fixture work survives route release and scope disposal cancels its timer and transport access",
    (tester) async {
      var organization = skir.recordId("organization:one");
      final realm = skir.recordId("service:realm");
      final page = skir.ResourceId(value: "page:welcome");
      final document = fixtureAuthoringDocument(
        pages: [
          Page(
            pageId: page,
            bookId: null,
            name: "Welcome",
            configuration: skir.TypeSelection.unknown,
            chapter: "Town",
            priority: 0,
          ),
        ],
      );
      final transport = ScriptedAuthoringTransport(AsyncData(document));
      addTearDown(transport.dispose);
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWith((ref) => organization),
          realmIdProvider.overrideWithValue(realm),
          ...authoringFixtureOverrides(
            document: document,
            transport: transport,
          ),
        ],
      );
      addTearDown(container.dispose);
      final first = AuthoringScope(
        organizationId: organization,
        realmId: realm,
      );
      final route = container.listen(
        authoringWorkspaceProvider(first),
        (_, _) {},
      );
      final workspace = route.read();
      final staged = workspace.edit(
        label: "Pending rename",
        apply: (edit) => edit.set(
          skir.ValueLocation(
            resource: page,
            path: skir.ValuePath(
              segments: [skir.PathSegment.createField(name: "name")],
            ),
          ),
          skir.DataValue.wrapStringValue("Draft welcome"),
        ),
      ) as AuthoringEditStaged;
      route.close();
      await tester.pump();
      expect(
        workspace.document
            .resource(page)!
            .authoredField("name")!
            .authoredString,
        "Draft welcome",
      );
      expect(
        container.read(localWorkProvider).entries.values.single.label,
        "Pending rename",
      );
      expect(transport.requests, isEmpty);
      organization = skir.recordId("organization:two");
      container.invalidate(organizationIdProvider);
      container.read(localWorkControllerProvider);
      final second = AuthoringScope(
        organizationId: organization,
        realmId: realm,
      );
      final nextRoute = container.listen(
        authoringWorkspaceProvider(second),
        (_, _) {},
      );
      final next = nextRoute.read();
      expect(next, isNot(same(workspace)));
      expect(
        next.document.resource(page)!.authoredField("name")!.authoredString,
        "Welcome",
      );
      expect(() => workspace.attach(page), throwsStateError);
      await workspace.save(staged.group);
      await workspace.refreshConfirmed();
      await tester.pump(AuthoringWorkspace.debounce);
      expect(transport.requests, isEmpty);
      expect(transport.fetches, 0);
      expect(container.read(localWorkProvider).entries, isEmpty);
      nextRoute.close();
      container.dispose();
      await tester.pump();
    },
  );

  test("fixture error observations use production workspace projection", () {
    final error = StateError("External authoring failure");
    final scope = AuthoringScope(
      organizationId: skir.recordId("organization:one"),
      realmId: skir.recordId("service:realm"),
    );
    final container = ProviderContainer.test(
      overrides: authoringFixtureOverrides(
        scope: scope,
        observation: AsyncError(error, StackTrace.current),
      ),
    );
    addTearDown(container.dispose);
    final route = container.listen(
      workingAuthoringDocumentProvider(scope),
      (_, _) {},
    );
    expect(route.read().error, same(error));
    route.close();
  });
}
