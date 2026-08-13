import "dart:convert";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:localstorage/localstorage.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "color_library.freezed.dart";
part "color_library.g.dart";

enum ColorFieldFormat { hex, rgb, hsl }

@freezed
abstract class ColorLibraryState with _$ColorLibraryState {
  const factory ColorLibraryState({
    @Default([]) List<int> recent,
    @Default([]) List<int> favorites,
    @Default(ColorFieldFormat.hex) ColorFieldFormat format,
  }) = _ColorLibraryState;
}

abstract interface class ColorLibraryStorage {
  String? read();

  void write(String value);
}

final class LocalColorLibraryStorage implements ColorLibraryStorage {
  const LocalColorLibraryStorage();

  static const key = "editor.colorLibrary.v1";

  @override
  String? read() => localStorage.getItem(key);

  @override
  void write(String value) => localStorage.setItem(key, value);
}

final class MemoryColorLibraryStorage implements ColorLibraryStorage {
  MemoryColorLibraryStorage([this.value]);

  String? value;

  @override
  String? read() => value;

  @override
  void write(String value) => this.value = value;
}

@riverpod
ColorLibraryStorage colorLibraryStorage(Ref ref) =>
    const LocalColorLibraryStorage();

@Riverpod(keepAlive: true)
class ColorLibrary extends _$ColorLibrary {
  static const recentLimit = 10;
  static const favoritesLimit = 24;

  @override
  ColorLibraryState build() => _decode(ref.watch(colorLibraryStorageProvider));

  void recordRecent(int argb) {
    final recent = [argb, ...state.recent.where((value) => value != argb)];
    _save(state.copyWith(recent: recent.take(recentLimit).toList()));
  }

  void toggleFavorite(int argb) {
    if (state.favorites.contains(argb)) {
      removeFavorite(argb);
      return;
    }
    _save(
      state.copyWith(
        favorites: [argb, ...state.favorites].take(favoritesLimit).toList(),
      ),
    );
  }

  void removeFavorite(int argb) {
    _save(
      state.copyWith(
        favorites: state.favorites.where((value) => value != argb).toList(),
      ),
    );
  }

  void moveFavorite(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.favorites.length) return;
    final target = newIndex.clamp(0, state.favorites.length - 1);
    if (target == oldIndex) return;
    final favorites = [...state.favorites];
    final value = favorites.removeAt(oldIndex);
    favorites.insert(target, value);
    _save(state.copyWith(favorites: favorites));
  }

  void replaceFavorites(List<int> favorites) {
    final normalized = <int>[];
    for (final value in favorites) {
      if (!normalized.contains(value)) normalized.add(value);
      if (normalized.length == favoritesLimit) break;
    }
    _save(state.copyWith(favorites: normalized));
  }

  void setFormat(ColorFieldFormat format) {
    if (state.format == format) return;
    _save(state.copyWith(format: format));
  }

  void _save(ColorLibraryState next) {
    state = next;
    try {
      ref
          .read(colorLibraryStorageProvider)
          .write(
            jsonEncode({
              "recent": next.recent.map(_encodeColor).toList(),
              "favorites": next.favorites.map(_encodeColor).toList(),
              "format": next.format.name,
            }),
          );
    } on Object {
      return;
    }
  }
}

ColorLibraryState _decode(ColorLibraryStorage storage) {
  try {
    final source = storage.read();
    if (source == null) return const ColorLibraryState();
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) return const ColorLibraryState();
    return ColorLibraryState(
      recent: _decodeColors(json["recent"], ColorLibrary.recentLimit),
      favorites: _decodeColors(json["favorites"], ColorLibrary.favoritesLimit),
      format: ColorFieldFormat.values.firstWhere(
        (value) => value.name == json["format"],
        orElse: () => ColorFieldFormat.hex,
      ),
    );
  } on Object {
    return const ColorLibraryState();
  }
}

List<int> _decodeColors(Object? source, int limit) {
  if (source is! List) return const [];
  final colors = <int>[];
  for (final item in source) {
    if (item is! String || !RegExp(r"^[0-9A-Fa-f]{8}$").hasMatch(item)) {
      continue;
    }
    final value = int.parse(item, radix: 16);
    if (!colors.contains(value)) colors.add(value);
    if (colors.length == limit) break;
  }
  return colors;
}

String _encodeColor(int value) =>
    value.toUnsigned(32).toRadixString(16).padLeft(8, "0").toUpperCase();
