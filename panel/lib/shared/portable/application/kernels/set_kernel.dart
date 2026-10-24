import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's set operations. Results keep the first occurrence of equal
/// items of the first set, with their identities.
final class PanelSetKernel implements skir.SetKernel {
  const PanelSetKernel();

  @override
  List<skir.ListItem> difference(
    List<skir.ListItem> first,
    List<skir.ListItem> second,
  ) {
    final excluded = {
      for (final item in second) canonicalAuthoredValue(item.value),
    };
    return distinctItems(
      first.where(
        (item) => !excluded.contains(canonicalAuthoredValue(item.value)),
      ),
    );
  }

  @override
  List<skir.ListItem> intersect(
    List<skir.ListItem> first,
    List<skir.ListItem> second,
  ) {
    final included = {
      for (final item in second) canonicalAuthoredValue(item.value),
    };
    return distinctItems(
      first.where(
        (item) => included.contains(canonicalAuthoredValue(item.value)),
      ),
    );
  }
}
