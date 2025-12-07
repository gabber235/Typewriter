import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/widgets/app/components/version_filter.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

List<Version> _generateVersions({
  required bool hasEpoch,
  required int epochs,
  required int majorsPerEpoch,
  required int minorsPerMajor,
  required int patchesPerMinor,
}) {
  final result = <Version>[];
  final epochStart = hasEpoch ? 0 : 0;
  final epochEnd = hasEpoch ? (epochs - 1) : 0;

  for (var e = epochStart; e <= epochEnd; e++) {
    for (var maj = 0; maj < majorsPerEpoch; maj++) {
      for (var mi = 0; mi < minorsPerMajor; mi++) {
        for (var p = 0; p < patchesPerMinor; p++) {
          final effMajor = e * 1000 + maj;
          result.add(Version(effMajor, mi, p));
        }
      }
    }
  }
  result.sort((a, b) => b.compareTo(a));
  return result;
}

Widget _storyScaffold({
  required bool hasEpoch,
  required List<Version> versions,
}) {
  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final filter = useState(const VersionFilter());
        final filtered = useMemoized(
          () =>
              versions.where((v) => filter.value.matches(v)).toList()
                ..sort((a, b) => b.compareTo(a)),
          [filter.value],
        );

        return Padding(
          padding: const .all(20.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              VersionFilterBar(
                filtered: filtered,
                filter: filter,
                hasEpoch: hasEpoch,
              ),
              const SizedBox(height: 12),
              Text(
                "Showing ${filtered.length} of ${versions.length} versions",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    const tileWidth = 140.0;
                    final crossAxisCount = (maxWidth / tileWidth)
                        .clamp(1, 8)
                        .floor();
                    if (filtered.length <= 30) {
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final v in filtered)
                              Chip(
                                label: Text(v.canonicalizedVersion),
                                materialTapTargetSize: .shrinkWrap,
                                visualDensity: .compact,
                              ),
                          ],
                        ),
                      );
                    }
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 3.5,
                      children: [
                        for (final v in filtered)
                          Chip(
                            label: Text(v.canonicalizedVersion),
                            materialTapTargetSize: .shrinkWrap,
                            visualDensity: .compact,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: "Default", type: VersionFilterBar)
Widget versionFilterBarDefaultUseCase(BuildContext context) {
  final hasEpoch = context.knobs.boolean(
    label: "Has Epoch",
    initialValue: false,
  );
  final dataset = context.knobs.object.dropdown(
    label: "Dataset size",
    options: const [2, 3, 4],
    initialOption: 2,
    labelBuilder: (o) {
      switch (o) {
        case 2:
          return "Small (2×3×3)";
        case 3:
          return "Medium (3×4×4)";
        default:
          return "Large (4×6×6)";
      }
    },
  );

  final versions = _generateVersions(
    hasEpoch: hasEpoch,
    epochs: hasEpoch ? 2 : 1,
    majorsPerEpoch: dataset == 2 ? 3 : (dataset == 3 ? 4 : 6),
    minorsPerMajor: dataset == 2 ? 3 : (dataset == 3 ? 4 : 6),
    patchesPerMinor: dataset == 2 ? 3 : (dataset == 3 ? 4 : 6),
  );

  return _storyScaffold(hasEpoch: hasEpoch, versions: versions);
}

@widgetbook.UseCase(name: "Epoch + Large", type: VersionFilterBar)
Widget versionFilterBarEpochLargeUseCase(BuildContext context) {
  final versions = _generateVersions(
    hasEpoch: true,
    epochs: 2,
    majorsPerEpoch: 8,
    minorsPerMajor: 6,
    patchesPerMinor: 4,
  );
  return _storyScaffold(hasEpoch: true, versions: versions);
}
