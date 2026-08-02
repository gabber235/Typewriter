import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Version number segment filter abstraction used by the query parser and UI.
sealed class VersionPartFilter {
  const VersionPartFilter();
  bool matches(int value);
  @override
  String toString();
}

/// Matches any integer value.
class AnyPart extends VersionPartFilter {
  const AnyPart();
  @override
  bool matches(int value) => true;
  @override
  String toString() => "*";
}

/// Matches when a value equals the fixed integer.
class FixedPart extends VersionPartFilter {
  const FixedPart(this.value);
  final int value;
  @override
  bool matches(int value) => value == this.value;
  @override
  String toString() => value.toString();
}

/// Matches when a value is within [from, to] inclusive. Ends can be null.
class RangePart extends VersionPartFilter {
  const RangePart(this.from, this.to);
  final int? from;
  final int? to;

  @override
  bool matches(int value) {
    if (from != null && value < from!) return false;
    if (to != null && value > to!) return false;
    return true;
  }

  @override
  String toString() {
    final fromStr = from?.toString() ?? "";
    final toStr = to?.toString() ?? "";
    return "$fromStr-$toStr";
  }
}

/// Query filter across epoch.semanticMajor.minor.patch.
class VersionFilter {
  const VersionFilter({
    this.epoch = const AnyPart(),
    this.semanticMajor = const AnyPart(),
    this.minor = const AnyPart(),
    this.patch = const AnyPart(),
  });

  final VersionPartFilter epoch;
  final VersionPartFilter semanticMajor;
  final VersionPartFilter minor;
  final VersionPartFilter patch;

  VersionFilter copyWith({
    VersionPartFilter? epoch,
    VersionPartFilter? semanticMajor,
    VersionPartFilter? minor,
    VersionPartFilter? patch,
  }) {
    return VersionFilter(
      epoch: epoch ?? this.epoch,
      semanticMajor: semanticMajor ?? this.semanticMajor,
      minor: minor ?? this.minor,
      patch: patch ?? this.patch,
    );
  }

  /// Returns true if [v] matches all segment constraints.
  bool matches(Version v) {
    final e = v.major ~/ 1000;
    final maj = v.major % 1000;
    if (!epoch.matches(e)) return false;
    if (!semanticMajor.matches(maj)) return false;
    if (!minor.matches(v.minor)) return false;
    if (!patch.matches(v.patch)) return false;
    return true;
  }

  bool get isEmpty =>
      epoch is AnyPart &&
      semanticMajor is AnyPart &&
      minor is AnyPart &&
      patch is AnyPart;

  bool get isNotEmpty => !isEmpty;

  /// Formats the filter to a user-display pattern.
  String display(bool hasEpoch) {
    var string = "";
    if (hasEpoch) string += "$epoch.";
    return string += "$semanticMajor.$minor.$patch";
  }

  /// Removes the most specific constraint.
  VersionFilter unwind() {
    if (patch is! AnyPart) return copyWith(patch: const AnyPart());
    if (minor is! AnyPart) return copyWith(minor: const AnyPart());
    if (semanticMajor is! AnyPart) {
      return copyWith(semanticMajor: const AnyPart());
    }
    return copyWith(epoch: const AnyPart());
  }
}

/// Parser to convert user text patterns into [VersionFilter].
// ignore: avoid_classes_with_only_static_members
class VersionFilterParser {
  static VersionFilter parse({required String query, required bool hasEpoch}) {
    final q = query.trim();
    if (q.isEmpty) return const VersionFilter();

    final parts = q.split(".").map(parsePart).toList();

    if (!hasEpoch && parts.length < 4) {
      parts.insert(0, const AnyPart());
    }

    while (parts.length < 4) {
      parts.add(const AnyPart());
    }

    final [epoch, major, minor, patch] = parts;
    return VersionFilter(
      epoch: epoch,
      semanticMajor: major,
      minor: minor,
      patch: patch,
    );
  }

  /// Parses one segment piece: "*", "12", "1-5", "-3", "7-".
  static VersionPartFilter parsePart(String part) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) return const AnyPart();

    if (trimmed == "*") return const AnyPart();

    if (trimmed.contains("-")) {
      final parts = trimmed
          .split("-")
          .map((e) => e.trim().asInt)
          .toList(growable: false);
      if (parts.length != 2) return const AnyPart();
      final low = parts[0];
      final high = parts[1];
      return RangePart(low, high);
    }

    final v = trimmed.asInt;
    if (v != null) return FixedPart(v);
    return const AnyPart();
  }

  /// Produces suggestion strings for the next segment based on [filtered].
  static List<String> suggestionStrings(
    VersionFilter filter,
    List<Version> filtered,
    bool hasEpoch, {
    int max = 10,
  }) {
    if (hasEpoch && filter.epoch is AnyPart) {
      return _suggestions(
        filtered,
        (v) => v.major ~/ 1000,
        (f) => filter.copyWith(epoch: f),
        hasEpoch,
        max,
      );
    } else if (filter.semanticMajor is AnyPart) {
      return _suggestions(
        filtered,
        (v) => v.major % 1000,
        (f) => filter.copyWith(semanticMajor: f),
        hasEpoch,
        max,
      );
    } else if (filter.minor is AnyPart) {
      return _suggestions(
        filtered,
        (v) => v.minor,
        (f) => filter.copyWith(minor: f),
        hasEpoch,
        max,
      );
    } else if (filter.patch is AnyPart) {
      return _suggestions(
        filtered,
        (v) => v.patch,
        (f) => filter.copyWith(patch: f),
        hasEpoch,
        max,
      );
    }
    return [];
  }

  static List<String> _suggestions(
    List<Version> filtered,
    int Function(Version v) toValue,
    VersionFilter Function(VersionPartFilter part) toFilter,
    bool hasEpoch,
    int max,
  ) {
    final values = filtered
        .map(toValue)
        .toSet()
        .sorted((a, b) => b.compareTo(a))
        .take(max)
        .map(FixedPart.new)
        .map((f) => toFilter(f))
        .map((f) => f.display(hasEpoch))
        .toList();
    return values;
  }
}

/// Expands a [VersionFilter] with only fixed/range parts into a list of [Version].
extension VersionFilterExpander on VersionFilter {
  /// Converts [filter] into explicit versions.
  List<Version> expand() {
    final result = <Version>[];
    for (final epoch in epoch.expand("Epoch")) {
      for (final major in semanticMajor.expand("Major")) {
        for (final minor in minor.expand("Minor")) {
          for (final patch in patch.expand("Patch")) {
            final effMajor = epoch * 1000 + major;
            result.add(Version(effMajor, minor, patch));
          }
        }
      }
    }
    return result;
  }

  int predictExpansion() {
    return epoch.predictExpansion() *
        semanticMajor.predictExpansion() *
        minor.predictExpansion() *
        patch.predictExpansion();
  }
}

extension VersionPartExpansion on VersionPartFilter {
  Iterable<int> expand(String name) sync* {
    switch (this) {
      case AnyPart():
        throw FormatException("Cannot use * as $name");
      case FixedPart(value: final v):
        yield v;
      case RangePart(:final from, :final to):
        for (var i = from ?? 0; i <= (to ?? 0); i++) {
          yield i;
        }
    }
  }

  int predictExpansion() {
    switch (this) {
      case AnyPart():
        return 0;
      case FixedPart():
        return 1;
      case RangePart(:final from, :final to):
        return (to ?? 0) - (from ?? 0) + 1;
    }
  }
}

/// A reusable filter bar for versions. Updates [filter] as the user types.
class VersionFilterBar extends HookWidget {
  const VersionFilterBar({
    required this.filtered,
    required this.filter,
    required this.hasEpoch,
    this.hintText = "Filter versions",
    super.key,
  });

  final List<Version> filtered;
  final ValueNotifier<VersionFilter> filter;
  final bool hasEpoch;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final queryController = useTextEditingController(text: "");

    final suggestionLabels = useMemoized(() {
      return VersionFilterParser.suggestionStrings(
        filter.value,
        filtered,
        hasEpoch,
        max: 9,
      );
    }, [filtered]);

    void applyQuery(String q) {
      final parsed = VersionFilterParser.parse(
        query: q.trim(),
        hasEpoch: hasEpoch,
      );
      filter.value = parsed;
    }

    void unwind() {
      final next = filter.value.unwind();
      filter.value = next;
      final text = next.isEmpty ? "" : next.display(hasEpoch);
      queryController.text = text;
    }

    void clear() {
      filter.value = const VersionFilter();
      queryController.text = "";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasEpoch
              ? "Pattern: epoch.major.minor.patch • Supports * and ranges (a-b)"
              : "Pattern: major.minor.patch • Supports * and ranges (a-b)",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        DecoratedTextField(
          focusNode: focusNode,
          controller: queryController,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.filter_alt),
            suffixIcon: filter.value.isEmpty
                ? null
                : InputIconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: "Unwind",
                    onPressed: unwind,
                  ),
            isDense: true,
          ),
          onChanged: applyQuery,
          surroundingActions: [
            if (filter.value.isNotEmpty) ...[
              ActionShortcut.intent(
                id: "version_filter_unwind",
                label: "Unwind",
                description: "Unwind the filter",
                intent: DeleteIntent,
                priority: 1001,
                onInvoke: (_) => unwind(),
              ),
              ActionShortcut(
                id: "version_filter_clear",
                label: "Clear",
                description: "Clear the filter",
                activators: [
                  AdaptiveSingleActivator(
                    LogicalKeyboardKey.delete,
                    control: true,
                  ),
                  AdaptiveSingleActivator(
                    LogicalKeyboardKey.backspace,
                    control: true,
                  ),
                ],
                priority: 1000,
                onInvoke: (_) => clear(),
              ),
            ],
          ],
        ),
        SizedBox(height: context.spacing.space2),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...suggestionLabels.take(8).map((label) {
              return ChoiceChip(
                label: Text(label),
                selected: false,
                onSelected: (_) {
                  queryController.text = label;
                  applyQuery(label);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),
          ],
        ),
      ],
    );
  }
}
