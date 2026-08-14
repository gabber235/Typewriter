import "package:riverpod_annotation/riverpod_annotation.dart";

part "icon_library.g.dart";

@Riverpod(keepAlive: true)
class IconLibrary extends _$IconLibrary {
  static const recentLimit = 10;

  @override
  List<String> build() => const [];

  void recordRecent(String identifier) {
    state = [
      identifier,
      ...state.where((value) => value != identifier),
    ].take(recentLimit).toList(growable: false);
  }
}
