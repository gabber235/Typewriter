import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  testWidgets("page edit commits one checked authored field change", (
    tester,
  ) async {
    final committed = <skir.EditIntent>[];
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          onApply: (intents) async => committed.addAll(intents),
        ),
        child: Consumer(
          builder: (context, value, child) {
            ref = value;
            value.watch(authoringSessionProvider(_organization, _realm));
            return const SizedBox();
          },
        ),
      ),
    );

    await ref.editPage(id: _page, name: "Renamed", expectedName: "Initial");

    expect(committed, hasLength(1));
    final set = committed.single as skir.EditIntent_setValueWrapper;
    expect(set.value.at, _field("name"));
    expect(set.value.value.authoredString, "Renamed");
  });

  testWidgets("page edit rejects a value changed since it was shown", (
    tester,
  ) async {
    var commits = 0;
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          onApply: (_) async {
            commits++;
          },
        ),
        child: Consumer(
          builder: (context, value, child) {
            ref = value;
            value.watch(authoringSessionProvider(_organization, _realm));
            return const SizedBox();
          },
        ),
      ),
    );

    await expectLater(
      ref.editPage(id: _page, name: "Local", expectedName: "Stale"),
      throwsA(isA<ApiException>()),
    );
    expect(commits, 0);
  });

  testWidgets("page edit checks every field before committing the batch", (
    tester,
  ) async {
    var commits = 0;
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          onApply: (_) async {
            commits++;
          },
        ),
        child: Consumer(
          builder: (context, value, child) {
            ref = value;
            value.watch(authoringSessionProvider(_organization, _realm));
            return const SizedBox();
          },
        ),
      ),
    );

    await expectLater(
      ref.editPage(
        id: _page,
        name: "Renamed",
        expectedName: "Initial",
        priority: 5,
        expectedPriority: 9,
      ),
      throwsA(isA<ApiException>()),
    );
    expect(commits, 0);
  });
}

List<Override> _overrides({
  required Future<void> Function(List<skir.EditIntent> intents) onApply,
}) => [
  organizationIdProvider.overrideWithValue(_organization),
  realmIdProvider.overrideWithValue(_realm),
  ...authoringSessionMockOverrides(initial: _state(), onApply: onApply),
];

AuthoringSessionState _state() {
  final catalog = receivedCheckedEditorCatalog(generation: _generation);
  return AuthoringSessionState(
    catalog: catalog,
    snapshot: skir.AuthoringSnapshot(
      snapshot: skir.SnapshotId(value: "snapshot:page"),
      generation: _generation,
      resources: [
        skir.AuthoringResource(
          id: _page,
          definition: skir.ResourceDefinitionId(value: "typewriter.page"),
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.unknown,
            fields: [
              skir.FieldValue(
                name: "name",
                value: skir.DataValue.wrapStringValue("Initial"),
              ),
              skir.FieldValue(
                name: "chapter",
                value: skir.DataValue.wrapStringValue("chapter"),
              ),
              skir.FieldValue(
                name: "priority",
                value: skir.DataValue.wrapInteger("2"),
              ),
            ],
          ),
        ),
      ],
      links: const [],
      findings: const [],
      observations: const [],
      absentInputToken: skir.InputToken(value: "absent"),
      findingsToken: skir.FindingsToken(value: "findings:page"),
    ),
  );
}

skir.ValueLocation _field(String name) => skir.ValueLocation(
  resource: _page,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]),
);

final _page = skir.ResourceId(value: "page:test");
final _generation = skir.CatalogGeneration(value: "catalog:page");
final _organization = recordId("organization:test");
final _realm = recordId("realm:test");
