import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("a later session loads the selections an earlier one stored", () async {
    final storage = FakeLocalStorage();
    final stored = [
      mappedSearchResult("first", skir.DataValue.wrapStringValue("First")),
      customSearchResult("typed", skir.DataValue.wrapStringValue("Typed")),
    ];
    await historyStorage(storage)
        .replaceResults(key: "recent", results: stored);

    final loaded = await historyStorage(storage)
        .loadValidResults(key: "recent", capacity: 5);

    expect([for (final result in loaded) result.id], ["first", "typed"]);
    expect([for (final result in loaded) result.title], ["first", "typed"]);
    expect(
      [for (final result in loaded) result.payload],
      [for (final result in stored) result.payload],
    );
  });

  test("loading returns at most the capacity, oldest dropped", () async {
    final storage = FakeLocalStorage();
    await historyStorage(storage).replaceResults(
      key: "recent",
      results: mappedTextResults(["newest", "middle", "oldest"]),
    );

    final loaded = await historyStorage(storage)
        .loadValidResults(key: "recent", capacity: 2);

    expect([for (final result in loaded) result.id], ["newest", "middle"]);
  });

  test("each history key keeps its own selections", () async {
    final storage = FakeLocalStorage();
    final history = historyStorage(storage);
    await history.replaceResults(
      key: "first",
      results: mappedTextResults(["one"]),
    );
    await history.replaceResults(
      key: "second",
      results: mappedTextResults(["two"]),
    );

    final first = await history.loadValidResults(key: "first", capacity: 5);
    final second = await history.loadValidResults(key: "second", capacity: 5);

    expect([for (final result in first) result.id], ["one"]);
    expect([for (final result in second) result.id], ["two"]);
  });

  group("an undecodable entry is dropped and the rest still load", () {
    // Each case breaks one part of an entry the storage wrote itself.
    final cases = <String, Object? Function(Map<String, Object?> entry)>{
      "not an object": (_) => "plain text",
      "no id": (entry) => {...entry}..remove("id"),
      "an empty provider": (entry) => {...entry, "provider": ""},
      "an unknown kind": (entry) => {...entry, "kind": "future"},
      "a selected value that is not base64": (entry) => {
        ...entry,
        "selected": "%%%",
      },
      "a mapped entry without its mapping": (entry) =>
          {...entry}..remove("mapping"),
      "a mapped entry without its distinct key": (entry) => {
        ...entry,
        "distinctKey": "",
      },
    };
    for (final MapEntry(key: name, value: breakEntry) in cases.entries) {
      test(name, () async {
        final storage = FakeLocalStorage();
        await historyStorage(storage).replaceResults(
          key: "recent",
          results: mappedTextResults(["broken", "valid"]),
        );
        final key = storage.items.keys.single;
        final [broken, valid] =
            jsonDecode(storage.items[key]!) as List<Object?>;
        storage.items[key] = jsonEncode([
          breakEntry(broken! as Map<String, Object?>),
          valid,
        ]);

        final loaded = await historyStorage(storage)
            .loadValidResults(key: "recent", capacity: 5);

        expect([for (final result in loaded) result.id], ["valid"]);
      });
    }
  });

  group("unreadable stored history loads as empty", () {
    for (final (name, stored) in [
      ("not JSON", "{not json"),
      ("JSON that is not a list", '{"id":"x"}'),
    ]) {
      test(name, () async {
        final storage = FakeLocalStorage();
        await historyStorage(
          storage,
        ).replaceResults(key: "recent", results: mappedTextResults(["valid"]));
        storage.items[storage.items.keys.single] = stored;

        expect(
          await historyStorage(storage)
              .loadValidResults(key: "recent", capacity: 5),
          isEmpty,
        );
      });
    }
  });

  test("a selection of a type the catalog no longer has is dropped", () async {
    final storage = FakeLocalStorage();
    final kept = typeDefinition("Kept", namespace: "history.test");
    final removed = typeDefinition("Removed", namespace: "history.test");
    await historyStorage(
      storage,
      catalog: testCheckedCatalog(
        types: [
          for (final type in [kept, removed])
            testPublishedRecord(type, const {}),
        ],
      ),
    ).replaceResults(
      key: "recent",
      results: [
        mappedSearchResult(
          "removed",
          skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: removed,
              arguments: const [],
            ),
            payload: skir.DataValue.createRecord(fields: const []),
          ),
        ),
        customSearchResult(
          "removed_custom",
          skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: removed,
              arguments: const [],
            ),
            payload: skir.DataValue.createRecord(fields: const []),
          ),
        ),
        mappedSearchResult(
          "nested",
          skir.DataValue.createListValue(
            items: [
              skir.ListItem(
                id: skir.ItemId(value: "a"),
                value: skir.DataValue.createNamed(
                  actualType: skir.NamedTypeUse(
                    definition: removed,
                    arguments: const [],
                  ),
                  payload: skir.DataValue.createRecord(fields: const []),
                ),
              ),
            ],
          ),
        ),
        mappedSearchResult(
          "kept",
          skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: kept,
              arguments: const [],
            ),
            payload: skir.DataValue.createRecord(fields: const []),
          ),
        ),
      ],
    );

    final loaded = await historyStorage(
      storage,
      catalog: testCheckedCatalog(
        types: [
          for (final type in [kept]) testPublishedRecord(type, const {}),
        ],
      ),
    ).loadValidResults(key: "recent", capacity: 5);

    expect([for (final result in loaded) result.id], ["kept"]);
  });
}
