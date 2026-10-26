import "package:typewriter_panel/typewriter_panel.dart";

/// A small seeded generator for property tests and seeded story data.
///
/// The same seed yields the same values in the same order, so a failing
/// property reproduces from its seed alone. Values are plain and readable;
/// tests that need a specific value write it out instead.
final class Generator {
  Generator(this.seed) : _random = Random(seed);

  /// The seed this generator was created with.
  final int seed;
  final Random _random;

  /// An integer in [min] (inclusive) to [max] (exclusive).
  int integer(int max, {int min = 0}) => min + _random.nextInt(max - min);

  /// True with [probability].
  bool chance(double probability) => _random.nextDouble() < probability;

  /// One of [values].
  T pick<T>(List<T> values) => values[_random.nextInt(values.length)];

  /// [count] values made by [value].
  List<T> list<T>(int count, T Function(Generator generator) value) => [
    for (var index = 0; index < count; index++) value(this),
  ];

  /// A lower case word of [length] letters, [length] picked when absent.
  String word({int? length}) {
    const letters = "abcdefghijklmnopqrstuvwxyz";
    return String.fromCharCodes([
      for (var index = 0; index < (length ?? integer(9, min: 3)); index++)
        letters.codeUnitAt(_random.nextInt(letters.length)),
    ]);
  }

  /// A title of [words] capitalized words.
  String title({int words = 2}) =>
      [for (var index = 0; index < words; index++) word().titleCase()]
          .join(" ");
}
