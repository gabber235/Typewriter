import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(const TypeCatalog([]));

  test("rejects an evaluated payload with the wrong type", () async {
    final transport = _FakeRealmSearchTransport();
    final source = _source(
      transport.watch,
      registry,
      payload: "server".asStringLiteral,
      payloadType: const IntegerType(width: IntegerWidth.signed64),
    );
    addTearDown(source.dispose);
    final terminal = source.snapshots.firstWhere(
      (snapshot) => snapshot.status == SearchSourceStatus.error,
    );

    source.search(_query("speed"));
    final snapshot = await terminal;

    expect(transport.requests, isEmpty);
    expect(snapshot.errorSummaries, isNotEmpty);
  });

  test("passes complete queries and replaces full snapshots", () async {
    final transport = _FakeRealmSearchTransport();
    final source = _source(transport.watch, registry);
    addTearDown(source.dispose);
    final snapshots = <SearchSourceSnapshot>[];
    final subscription = source.snapshots.listen(snapshots.add);
    addTearDown(subscription.cancel);
    final query = _query("speed");

    source.search(query);
    await Future<void>.delayed(Duration.zero);
    expect(transport.requests.single.query, query);
    final request = transport.requests.single;
    transport.controllers.single.add(
      RealmPresentationSearchUpdate.snapshot(
        subscriptionId: request.subscriptionId,
        status: SearchSourceStatus.ready,
        values: const [StringValue("speed"), StringValue("haste")],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(_resultIds(snapshots.last), ["speed", "haste"]);

    transport.controllers.single.add(
      RealmPresentationSearchUpdate.snapshot(
        subscriptionId: request.subscriptionId,
        status: SearchSourceStatus.ready,
        values: const [StringValue("strength")],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(_resultIds(snapshots.last), ["strength"]);
  });

  test("cancels stale query subscriptions and ignores stale updates", () async {
    final transport = _FakeRealmSearchTransport();
    final source = _source(transport.watch, registry);
    addTearDown(source.dispose);
    final snapshots = <SearchSourceSnapshot>[];
    final subscription = source.snapshots.listen(snapshots.add);
    addTearDown(subscription.cancel);

    source.search(_query("first"));
    final firstRequest = transport.requests.single;
    final firstController = transport.controllers.single;
    source.search(_query("second"));
    await Future<void>.delayed(Duration.zero);

    expect(transport.cancelled, contains(0));
    firstController.add(
      RealmPresentationSearchUpdate.snapshot(
        subscriptionId: firstRequest.subscriptionId,
        status: SearchSourceStatus.ready,
        values: const [StringValue("stale")],
      ),
    );
    final secondRequest = transport.requests.last;
    transport.controllers.last.add(
      RealmPresentationSearchUpdate.snapshot(
        subscriptionId: secondRequest.subscriptionId,
        status: SearchSourceStatus.ready,
        values: const [StringValue("current")],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(_resultIds(snapshots.last), ["current"]);
    expect(snapshots.expand(_resultIds), isNot(contains("stale")));
  });

  test("surfaces explicit unavailable updates", () async {
    final transport = _FakeRealmSearchTransport();
    final source = _source(transport.watch, registry);
    addTearDown(source.dispose);
    final terminal = source.snapshots.firstWhere(
      (snapshot) => snapshot.status == SearchSourceStatus.error,
    );

    source.search(_query("speed"));
    final request = transport.requests.single;
    transport.controllers.single.add(
      RealmPresentationSearchUpdate.unavailable(
        subscriptionId: request.subscriptionId,
        diagnostics: const [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message: "Realm search handler is unavailable",
          ),
        ],
      ),
    );
    final snapshot = await terminal;

    expect(
      snapshot.errorSummaries.single.message,
      "Realm search handler is unavailable",
    );
  });
}

const _queryBindingId = BindingId(10);
const _candidateBindingId = BindingId(20);

RealmPresentationSearchSource _source(
  RealmPresentationSearchTransport transport,
  TypeRegistry registry, {
  TypedExpression? payload,
  TypeExpression payloadType = const StringType(),
}) => RealmPresentationSearchSource(
  provider: RealmCallbackSearchProvider(
    actionId: const RealmActionId(namespace: "minecraft", name: "effects"),
    payload: payload ?? "server".asStringLiteral,
    result: SearchResultMapping(
      bindingId: _candidateBindingId,
      key: _binding(_candidateBindingId),
      selectedValue: _binding(_candidateBindingId),
      presentation: PresentationNode(
        id: "realm.result",
        element: TextElement(_binding(_candidateBindingId)),
      ),
    ),
  ),
  payloadType: payloadType,
  resultType: const StringType(),
  transport: transport,
  queryBindingId: _queryBindingId,
  expressions: const ExpressionContext(bindings: BindingEnvironment({})),
  registry: registry,
  budget: const ExpressionBudget(),
  providerKey: "realm.test",
);

SearchQueryContext _query(String value) => SearchQueryContext(
  normalizedQuery: value,
  selectors: const [
    SearchParsedSelector(
      selectorId: "category",
      key: "category:",
      value: "beneficial",
    ),
  ],
);

TypedExpression _binding(BindingId id) => TypedExpression(
  resultType: const StringType(),
  expression: BindingExpression(BindingReference(bindingId: id)),
);

List<String> _resultIds(SearchSourceSnapshot snapshot) => snapshot.nodes
    .cast<SearchResultNode>()
    .map((node) => node.result.id)
    .toList(growable: false);

final class _FakeRealmSearchTransport {
  final requests = <RealmPresentationSearchRequest>[];
  final controllers = <StreamController<RealmPresentationSearchUpdate>>[];
  final cancelled = <int>[];

  Stream<RealmPresentationSearchUpdate> watch(
    RealmPresentationSearchRequest request,
  ) {
    final index = controllers.length;
    late StreamController<RealmPresentationSearchUpdate> controller;
    controller = StreamController<RealmPresentationSearchUpdate>.broadcast(
      sync: true,
      onCancel: () => cancelled.add(index),
    );
    requests.add(request);
    controllers.add(controller);
    return controller.stream;
  }
}
