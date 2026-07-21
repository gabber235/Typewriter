import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

Future<List<OrganizationJoinRequest>> readJoinRequests(
  ProviderContainer container,
) async {
  final result = Completer<List<OrganizationJoinRequest>>();
  final subscription = container.listen(organizationJoinRequestsProvider, (
    previous,
    next,
  ) {
    if (result.isCompleted) return;
    switch (next) {
      case AsyncData(:final value):
        result.complete(value);
      case AsyncError(:final error, :final stackTrace):
        result.completeError(error, stackTrace);
      default:
    }
  }, fireImmediately: true);
  try {
    return await result.future;
  } finally {
    subscription.close();
  }
}

Future<T> readProviderValue<T>(
  ProviderSubscription<T> Function(void Function(T? previous, T next))
  subscribe,
) async {
  final result = Completer<T>();
  final subscription = subscribe((previous, next) {
    if (!result.isCompleted) result.complete(next);
  });
  try {
    return await result.future;
  } finally {
    subscription.close();
  }
}

class LoadingJoinRequestsNotifier extends OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    await Completer<void>().future;
  }
}

class ErrorJoinRequestsNotifier extends OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() =>
      Stream.error(Exception("Test error"));
}

class MockJoinRequestsNotifier extends OrganizationJoinRequests {
  MockJoinRequestsNotifier(this.requests);
  final List<OrganizationJoinRequest> requests;

  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    yield requests;
  }
}
