import "package:typewriter_panel/typewriter_panel.dart";

/// The browser's local storage, held in memory for one test.
///
/// Remembers what the panel stored under each key; a test seeds [items]
/// directly to start from what an earlier session left behind.
final class FakeLocalStorage implements LocalStorage {
  FakeLocalStorage([Map<String, String>? items]) : items = {...?items};

  /// The stored values by key.
  final Map<String, String> items;

  @override
  int get length => items.length;

  @override
  String? key(int index) => items.keys.elementAtOrNull(index);

  @override
  String? getItem(String key) => items[key];

  @override
  void removeItem(String key) => items.remove(key);

  @override
  void setItem(String key, String value) => items[key] = value;

  @override
  void clear() => items.clear();
}
