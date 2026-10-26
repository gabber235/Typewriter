# typewriter_testkit

Shared test kit for the panel. Tests import `package:typewriter_testkit/testing.dart`;
web code such as Widgetbook imports the web safe `package:typewriter_testkit/typewriter_testkit.dart`.

| Folder        | Holds                                                                |
| ------------- | -------------------------------------------------------------------- |
| `core/`       | `World`, `Trait`, `Slot`, `PanelStage`, `pumpPanel`, `eventually`    |
| `doubles/`    | One fake per seam; it remembers changes and holds no service rules   |
| `traits/`     | Sources a test sets: `signedIn`, `realm`, `offline`, `compact`, ...  |
| `drivers/`    | Read and act on the panel through semantics, as its user does        |
| `generators/` | A small seeded `Generator` for varied data                           |

```dart
final panel = await tester.pumpPanel([
  signedIn(ada, organization: acme),
  realm(books: [book("First")]),
]);
await panel.resources.row("First").open();
await panel.eventually(() => expect(panel.path, endsWith("book:first")));
```

Each trait fills one slot; two traits for the same slot fail with a message naming both.
