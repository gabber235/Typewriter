part of "page_elements.dart";

extension AuthoringPageElementsRef on Ref {
  Future<T> withReadyPageElements<T>(
    String pageId,
    FutureOr<T> Function(PageElements elements) operation,
  ) => _withReadyPageElements(container, pageId, operation);
}

extension AuthoringPageElementsWidgetRef on WidgetRef {
  Future<T> withReadyPageElements<T>(
    String pageId,
    FutureOr<T> Function(PageElements elements) operation,
  ) => _withReadyPageElements(
    ProviderScope.containerOf(context, listen: false),
    pageId,
    operation,
  );
}

Future<T> _withReadyPageElements<T>(
  ProviderContainer container,
  String pageId,
  FutureOr<T> Function(PageElements elements) operation,
) async {
  final organizationId = container.read(organizationIdProvider);
  final realmId = container.read(realmIdProvider);
  if (organizationId == null) throw ApiException.noOrganization();
  if (realmId == null) throw ApiException.badRequest("No realm selected");

  final realmChanged = Completer<void>();
  void markRealmChanged() {
    if (!realmChanged.isCompleted) realmChanged.complete();
  }

  final organizationSubscription = container.listen(organizationIdProvider, (
    _,
    next,
  ) {
    if (next != organizationId) markRealmChanged();
  });
  final realmSubscription = container.listen(realmIdProvider, (_, next) {
    if (next != realmId) markRealmChanged();
  });
  final session = container.read(
    authoringSessionProvider(organizationId, realmId).notifier,
  );
  final lease = session.acquirePage(recordId("page:$pageId"));
  final provider = pageElementsProvider(organizationId, realmId, pageId);
  final pageSubscription = container.listen(provider, (_, _) {});
  final elements = container.read(provider.notifier);
  final ready = container.read(provider.future);
  try {
    final isReady = await Future.any([
      Future.wait([lease.ready, ready], eagerError: true).then((_) => true),
      realmChanged.future.then((_) => false),
    ]);
    if (!isReady || realmChanged.isCompleted) {
      throw ApiException.conflict(
        "The selected realm changed while the page was loading",
      );
    }
    final result = await operation(elements);
    if (realmChanged.isCompleted) {
      throw ApiException.conflict(
        "The selected realm changed while the page was loading",
      );
    }
    return result;
  } finally {
    organizationSubscription.close();
    realmSubscription.close();
    pageSubscription.close();
    lease.release();
  }
}
