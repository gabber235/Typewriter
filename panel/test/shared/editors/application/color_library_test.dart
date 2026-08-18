import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("sanitizes stored colors and remembered format", () {
    final storage = MemoryColorLibraryStorage(
      '{"recent":["FF112233","invalid","ff112233","AA445566"],'
      '"favorites":["FF000001","FF000001","FF000002"],'
      '"format":"hsl"}',
    );
    final container = ProviderContainer(
      overrides: [colorLibraryStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final state = container.read(colorLibraryProvider);
    expect(state.recent, [0xFF112233, 0xAA445566]);
    expect(state.favorites, [0xFF000001, 0xFF000002]);
    expect(state.format, ColorFieldFormat.hsl);
  });

  test("orders and limits recent colors", () {
    final storage = MemoryColorLibraryStorage();
    final container = ProviderContainer(
      overrides: [colorLibraryStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final library = container.read(colorLibraryProvider.notifier);

    for (var index = 0; index < 12; index++) {
      library.recordRecent(0xFF000000 + index);
    }
    library.recordRecent(0xFF000005);

    final recent = container.read(colorLibraryProvider).recent;
    expect(recent, hasLength(ColorLibrary.recentLimit));
    expect(recent.first, 0xFF000005);
    expect(recent.toSet(), hasLength(recent.length));
  });

  test("supports favorite mutation, limits, and reordering", () {
    final container = ProviderContainer(
      overrides: [
        colorLibraryStorageProvider.overrideWithValue(
          MemoryColorLibraryStorage(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final library = container.read(colorLibraryProvider.notifier);

    for (var index = 0; index < 30; index++) {
      library.toggleFavorite(0xFF000000 + index);
    }
    expect(
      container.read(colorLibraryProvider).favorites,
      hasLength(ColorLibrary.favoritesLimit),
    );

    final first = container.read(colorLibraryProvider).favorites.first;
    library.moveFavorite(0, 3);
    expect(container.read(colorLibraryProvider).favorites[3], first);
    library.removeFavorite(first);
    expect(
      container.read(colorLibraryProvider).favorites,
      isNot(contains(first)),
    );
  });

  test("persistence failures remain nonfatal", () {
    final container = ProviderContainer(
      overrides: [
        colorLibraryStorageProvider.overrideWithValue(_ThrowingStorage()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(colorLibraryProvider), const ColorLibraryState());
    expect(
      () => container
          .read(colorLibraryProvider.notifier)
          .setFormat(ColorFieldFormat.rgb),
      returnsNormally,
    );
    expect(container.read(colorLibraryProvider).format, ColorFieldFormat.rgb);
  });
}

final class _ThrowingStorage implements ColorLibraryStorage {
  @override
  String? read() => throw StateError("Unavailable");

  @override
  void write(String value) => throw StateError("Unavailable");
}
