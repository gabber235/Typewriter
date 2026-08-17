import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class _Services extends Services {
  _Services(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build() => Stream.value(services);
}

Service _service(
  String id, {
  required skir.RecordId organization,
  List<ServiceRole>? roles,
  String? runsIn,
}) => Service(
  serviceId: recordId("service:$id"),
  revision: 1,
  name: id,
  roles: roles ?? [RealmServiceRole(version: "1")],
  createdAt: DateTime.utc(2026),
  organization: organization,
  runsIn: runsIn == null ? null : recordId("service:$runsIn"),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "Runs in candidates include Standalone and only valid Realm services",
    () async {
      final organization = recordId("organization:current");
      final otherOrganization = recordId("organization:other");
      final editing = _service(
        "editing",
        organization: organization,
        roles: [
          EngineServiceRole(version: "1"),
          RealmServiceRole(version: "1"),
        ],
      );
      final validRealm = _service("realm", organization: organization);
      final differentOrganization = _service(
        "foreign",
        organization: otherOrganization,
      );
      final notRealm = _service(
        "engine",
        organization: organization,
        roles: [EngineServiceRole(version: "1")],
      );
      final createsCycle = _service(
        "cycle",
        organization: organization,
        runsIn: "editing",
      );
      final source = servicePresentationCollection([
        editing,
        validRealm,
        differentOrganization,
        notRealm,
        createsCycle,
      ], editingService: editing);

      final snapshot = await source
          .watch(const PresentationCollectionQuery.all())
          .first;

      expect(snapshot.diagnostics, isEmpty);
      expect(_selectable(snapshot, "standalone"), isTrue);
      expect(_name(snapshot, "standalone"), "Standalone");
      expect(_selectable(snapshot, "realm"), isTrue);
      expect(_selectable(snapshot, "editing"), isFalse);
      expect(_reason(snapshot, "editing"), contains("itself"));
      expect(_selectable(snapshot, "foreign"), isFalse);
      expect(_reason(snapshot, "foreign"), contains("another organization"));
      expect(_selectable(snapshot, "engine"), isFalse);
      expect(_reason(snapshot, "engine"), contains("Realm service"));
      expect(_selectable(snapshot, "cycle"), isFalse);
      expect(_reason(snapshot, "cycle"), contains("cycle"));
    },
  );

  test(
    "Engine inspector exposes Runs in search and read only status",
    () async {
      final organization = recordId("organization:current");
      final engine = _service(
        "engine",
        organization: organization,
        roles: [EngineServiceRole(version: "1")],
      );
      final realm = _service("realm", organization: organization);
      final container = ProviderContainer.test(
        overrides: [
          servicesProvider.overrideWith(() => _Services([engine, realm])),
        ],
      );
      final subscription = container.listen(
        servicesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(servicesProvider.future);
      container
          .read(selectionProvider.notifier)
          .select(ServiceIdentifier(engine.serviceId));

      final selected = await _selected(container);
      final document = (selected as ServiceSelectable).document;
      final resolved = TypeRegistry(
        document.typeCatalog,
      ).resolve(document.rootType as NamedType);
      final root = document.presentations.single.root.element as ColumnElement;
      final runsInConditional =
          root.children
                  .singleWhere(
                    (node) => node.id == "service.runsIn.conditional",
                  )
                  .element
              as ConditionalElement;
      final runsIn = runsInConditional.whenTrue.element as SearchInputElement;

      expect(document.collections.single.id, serviceCollectionSourceId);
      expect(resolved.diagnostics, isEmpty);
      expect(resolved.valueOrNull, isNotNull);
      expect(runsIn.selectionMode, SearchSelectionMode.single);
      expect(runsIn.provider, isA<CollectionSearchProvider>());
      final condition = _evaluateCondition(document, runsInConditional);
      expect(condition.diagnostics, isEmpty);
      expect(condition.valueOrNull, const BooleanValue(true));
      expect(
        root.children.map((node) => node.id),
        isNot(contains("organization")),
      );
      expect(
        root.children.map((node) => node.id),
        isNot(contains("registration")),
      );
    },
  );

  test("Realm inspector hides Runs in", () async {
    final organization = recordId("organization:current");
    final realm = _service("realm", organization: organization);
    final container = ProviderContainer.test(
      overrides: [
        servicesProvider.overrideWith(() => _Services([realm])),
      ],
    );
    final subscription = container.listen(
      servicesProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(servicesProvider.future);
    container
        .read(selectionProvider.notifier)
        .select(ServiceIdentifier(realm.serviceId));

    final selected = await _selected(container);
    final document = (selected as ServiceSelectable).document;
    final resolved = TypeRegistry(
      document.typeCatalog,
    ).resolve(document.rootType as NamedType);
    final root = document.presentations.single.root.element as ColumnElement;

    expect(resolved.diagnostics, isEmpty);
    expect(resolved.valueOrNull, isNotNull);
    final runsInConditional =
        root.children
                .singleWhere((node) => node.id == "service.runsIn.conditional")
                .element
            as ConditionalElement;
    expect(runsInConditional.whenFalse, isNull);
    final condition = _evaluateCondition(document, runsInConditional);
    expect(condition.diagnostics, isEmpty);
    expect(condition.valueOrNull, const BooleanValue(false));
  });
}

TypeResult<DataValue> _evaluateCondition(
  EditorDocument document,
  ConditionalElement conditional,
) {
  final registry = TypeRegistry(document.typeCatalog);
  final bindingType = switch (document.rootType) {
    final NamedType type => registry.resolve(type).valueOrNull!.representation,
    final type => type,
  };
  return conditional.condition.evaluate(
    ExpressionContext(
      bindings: BindingEnvironment({
        const BindingId(0): BindingSnapshot(
          type: bindingType,
          value: document.confirmedValue,
          revision: document.revision,
        ),
      }),
    ),
    registry: registry,
  );
}

String _name(PresentationCollectionSnapshot snapshot, String id) =>
    (_field(snapshot, id, "name") as StringValue).value;

bool _selectable(PresentationCollectionSnapshot snapshot, String id) =>
    (_field(snapshot, id, "selectable") as BooleanValue).value;

String? _reason(PresentationCollectionSnapshot snapshot, String id) {
  final value = _field(snapshot, id, "unavailableReason");
  return switch (value) {
    PolymorphicValue(value: UnitValue()) => null,
    PolymorphicValue(
      value: RecordValue(fields: {"value": StringValue(:final value)}),
    ) =>
      value,
    _ => throw StateError("Unexpected unavailable reason: $value"),
  };
}

DataValue _field(
  PresentationCollectionSnapshot snapshot,
  String id,
  String name,
) {
  final row = snapshot.row(StringValue(id));
  if (row == null) throw StateError("Missing Service row: $id");
  return (row.value as RecordValue).fields[name]!;
}

Future<Selectable> _selected(ProviderContainer container) async {
  final completer = Completer<Selectable>();
  final subscription = container.listen(selectedProvider, (_, next) {
    if (!completer.isCompleted &&
        next.hasValue &&
        next.requireValue.isNotEmpty) {
      completer.complete(next.requireValue.single);
    } else if (!completer.isCompleted && next.hasError) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);
  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}
