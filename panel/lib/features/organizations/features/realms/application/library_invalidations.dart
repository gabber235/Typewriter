import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "library_invalidations.g.dart";

extension LibraryInvalidationRef on Ref {
  void invalidateOnLibraryChange(skir.LibraryResourceKind resource) {
    listen(libraryInvalidationsProvider(resource), (previous, next) {
      final previousRevision = switch (previous) {
        AsyncData<int>(:final value) => value,
        _ => null,
      };
      final nextRevision = switch (next) {
        AsyncData<int>(:final value) => value,
        _ => null,
      };
      if (previousRevision != null &&
          nextRevision != null &&
          previousRevision != nextRevision) {
        invalidateSelf();
      }
    });
  }
}

@riverpod
Stream<int> libraryInvalidations(Ref ref, skir.LibraryResourceKind resource) {
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) {
    return Stream.value(0);
  }
  final address = RealmServiceAddress(
    organizationId: organizationId,
    realmId: realmId,
  );
  final request = skir.WatchLibraryInvalidationsRequest();
  return ref.watchRequest(
    subject: address.request("library.invalidate.watch.v2"),
    listenSubject: address.event("library.invalidate.watch.v2"),
    requestBytes: skir.WatchLibraryInvalidationsRequest.serializer.toBytes(
      request,
    ),
    serializer: skir.WatchLibraryInvalidationsResponse.serializer,
    transformer: (previous, response) => switch (response) {
      skir.WatchLibraryInvalidationsResponse_initialWrapper(:final value) =>
        value.revision,
      skir.WatchLibraryInvalidationsResponse_invalidatedWrapper(:final value)
          when value.resources.contains(resource) &&
              value.revision > (previous ?? 0) =>
        value.revision,
      skir.WatchLibraryInvalidationsResponse_invalidatedWrapper() =>
        previous ?? 0,
      skir.WatchLibraryInvalidationsResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.WatchLibraryInvalidationsResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
    },
  );
}
