import "package:typewriter_panel/main.dart";

extension ListX<T> on List<T> {
  T? randomOrNull() {
    if (isEmpty) return null;
    return elementAt(random.nextInt(length));
  }
}
