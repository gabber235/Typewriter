import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_resource_navigation.g.dart";

abstract interface class AuthoringResourceNavigationAdapter {
  bool supports(String handler);

  Future<void> open(Ref ref, OpenAuthoringResourceEffect effect);
}

final class AuthoringResourceNavigationRegistry {
  AuthoringResourceNavigationRegistry(
    Iterable<AuthoringResourceNavigationAdapter> adapters,
  ) : _adapters = List.unmodifiable(adapters);

  final List<AuthoringResourceNavigationAdapter> _adapters;

  bool supports(String handler) =>
      _adapters.where((adapter) => adapter.supports(handler)).length == 1;

  Future<bool> open(
    Ref ref,
    String? handler,
    OpenAuthoringResourceEffect effect,
  ) async {
    if (handler == null) return false;
    final matches = _adapters.where((adapter) => adapter.supports(handler));
    if (matches.length != 1) return false;
    await matches.single.open(ref, effect);
    return true;
  }
}

@Riverpod(keepAlive: true)
AuthoringResourceNavigationRegistry authoringResourceNavigationRegistry(
  Ref ref,
) => AuthoringResourceNavigationRegistry(const [
  BookAuthoringNavigationAdapter(),
  TagAuthoringNavigationAdapter(),
]);
