import "package:typewriter_testkit/src/core/world.dart";

/// One source of a test world that exactly one trait may set.
///
/// A world built from two traits for the same slot would depend on their
/// order, so [World.build] refuses it and names both traits instead.
final class Slot {
  const Slot(this.name);

  /// Who is signed in and which organizations they belong to.
  static const session = Slot("session");

  /// The authoring content of the Realm the panel opens.
  static const realm = Slot("realm");

  /// The operations the Realm offers on its resources.
  static const operations = Slot("operations");

  /// Whether the panel reaches the backend.
  static const connection = Slot("connection");

  /// How long the doubles take to answer.
  static const latency = Slot("latency");

  /// The size of the window the panel renders in.
  static const window = Slot("window");

  /// The theme mode the user chose.
  static const appearance = Slot("appearance");

  final String name;

  @override
  String toString() => name;
}

/// One composable piece of a test world: a source the panel reads, or an edge
/// case of that source.
///
/// Traits set sources (the signed in session, seeded repositories, the
/// connection), never values the panel derives from them. A test lists the
/// traits its case needs; everything else keeps the world's defaults.
abstract class Trait {
  const Trait();

  /// The source this trait sets.
  Slot get slot;

  /// Writes this trait's source into the world being built.
  void applyTo(WorldBuilder world);

  /// How a duplicate slot error names this trait.
  String get description;

  @override
  String toString() => description;
}
