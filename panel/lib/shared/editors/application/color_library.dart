import "package:typewriter_panel/typewriter_panel.dart";

part "color_library.freezed.dart";
part "color_library.g.dart";

/// The notation used when the color editor displays a value.
enum ColorFieldFormat { hex, rgb, hsl }

/// Persisted preferences and reusable colors for the editor color picker.
///
/// The notifier owns the in memory state and writes a best effort snapshot to
/// [ColorLibraryStorage] after each change. Recent colors are ordered by most
/// recent use. Favorites preserve caller order, contain no duplicates, and are
/// capped so malformed or old storage cannot grow the picker without bound.
@freezed
abstract class ColorLibraryState with _$ColorLibraryState {
  const factory ColorLibraryState({
    @Default([]) List<int> recent,
    @Default([]) List<int> favorites,
    @Default(ColorFieldFormat.hex) ColorFieldFormat format,
  }) = _ColorLibraryState;
}

/// Storage boundary for the color library's serialized preferences.
///
/// Implementations may be persistent or ephemeral. Read and write failures are
/// intentionally handled by the library, so storage loss resets preferences
/// without blocking color editing.
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

/// Keeps color picker preferences alive across editor widget lifecycles.
@Riverpod(keepAlive: true)
class ColorLibrary extends _$ColorLibrary {
  static const recentLimit = 10;
  static const favoritesLimit = 24;

  @override
  ColorLibraryState build() => _decode(ref.watch(colorLibraryStorageProvider));

  /// Records [argb] at the front of the recent list and removes duplicates.
  void recordRecent(int argb) {
    final recent = [argb, ...state.recent.where((value) => value != argb)];
    _save(state.copyWith(recent: recent.take(recentLimit).toList()));
  }

  /// Adds [argb] to favorites, or removes it when already present.
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

  /// Replaces favorites with a unique, ordered list within the storage limit.
  ///
  /// This is used when the picker commits a reorder or imported selection.
  void replaceFavorites(List<int> favorites) {
    final normalized = <int>[];
    for (final value in favorites) {
      if (!normalized.contains(value)) normalized.add(value);
      if (normalized.length == favoritesLimit) break;
    }
    _save(state.copyWith(favorites: normalized));
  }

  /// Persists the notation preference used by subsequent color fields.
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
