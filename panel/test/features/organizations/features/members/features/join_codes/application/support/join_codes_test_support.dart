import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

Future<List<OrganizationJoinCode>> readJoinCodes(
  ProviderContainer container,
) async {
  final result = Completer<List<OrganizationJoinCode>>();
  final subscription = container.listen(organizationJoinCodesProvider, (
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

class LoadingJoinCodesNotifier extends OrganizationJoinCodes {
  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    await Completer<void>().future;
  }
}

class MockJoinCodesNotifier extends OrganizationJoinCodes {
  MockJoinCodesNotifier(this.codes);
  final List<OrganizationJoinCode> codes;

  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    yield codes;
  }
}
