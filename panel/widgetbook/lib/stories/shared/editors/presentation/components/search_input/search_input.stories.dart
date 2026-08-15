import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/search_input/search_input_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/search_input/search_input_story.dart";

const _path = "[Shared]/Editors/Presentation/Components/SearchInput";

enum _Scenario {
  ready,
  selectors,
  loading,
  partialError,
  empty,
  history,
  globalLimit,
  localLimits,
}

extension on _Scenario {
  String get label => switch (this) {
    _Scenario.ready => "Ready",
    _Scenario.selectors => "Selectors",
    _Scenario.loading => "Loading",
    _Scenario.partialError => "Partial error",
    _Scenario.empty => "Empty",
    _Scenario.history => "History",
    _Scenario.globalLimit => "Global limit",
    _Scenario.localLimits => "Local limits",
  };
}

@widgetbook.UseCase(
  name: "Playground",
  type: PresentationSearchInput,
  path: _path,
)
Widget searchInputPlayground(BuildContext context) {
  final scenario = context.knobs.object.dropdown(
    label: "Scenario",
    options: _Scenario.values,
    initialOption: _Scenario.ready,
    labelBuilder: (value) => value.label,
  );
  final mode = context.knobs.object.dropdown(
    label: "Selection mode",
    options: SearchSelectionMode.values,
    initialOption: SearchSelectionMode.single,
    labelBuilder: (value) => switch (value) {
      SearchSelectionMode.single => "Single",
      SearchSelectionMode.multiple => "Multiple",
    },
  );
  final initialSelection = context.knobs.object.dropdown<String>(
    label: "Initial selection",
    options: effectNames,
    initialOption: "Strength",
    labelBuilder: (value) => value,
  );
  final maximumExtent = context.knobs.double.slider(
    label: "Maximum result height",
    initialValue: 280,
    min: 120,
    max: 480,
  );
  final width = context.knobs.double.slider(
    label: "Control width",
    initialValue: 520,
    min: 280,
    max: 760,
  );
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final readOnly = context.knobs.boolean(label: "Read only");
  final configuration = _configuration(scenario);
  final multipleValues = <DataValue>{
    StringValue(initialSelection),
    const StringValue("Fire Resistance"),
  }.toList();
  final isMultiple = mode == SearchSelectionMode.multiple;

  return SearchInputStory(
    key: ValueKey((scenario, mode, initialSelection)),
    element: searchStoryElement(
      provider: configuration.provider,
      mode: mode,
      maximumExtent: maximumExtent,
      label: isMultiple ? "Active effects" : "Minecraft effect",
    ),
    type: isMultiple
        ? const ListType(element: StringType())
        : const StringType(),
    initialValue: isMultiple
        ? ListValue(multipleValues)
        : StringValue(initialSelection),
    sourceBuilder: configuration.sourceBuilder,
    enabled: enabled,
    readOnly: readOnly,
    width: width,
  );
}

@widgetbook.UseCase(
  name: "Live Iconify",
  type: PresentationSearchInput,
  path: _path,
)
Widget liveIconifySearchInput(BuildContext context) {
  final maximumExtent = context.knobs.double.slider(
    label: "Maximum result height",
    initialValue: 280,
    min: 120,
    max: 480,
  );
  final width = context.knobs.double.slider(
    label: "Control width",
    initialValue: 520,
    min: 280,
    max: 760,
  );
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final readOnly = context.knobs.boolean(label: "Read only");
  final element = iconifySearchPresentation().element as SearchInputElement;

  return SearchInputStory(
    element: element.copyWith(maximumExtent: maximumExtent.asFloatLiteral),
    type: NamedType(standardTypeRefs.iconifyIcon),
    initialValue: const StringValue("mdi:map-marker-star"),
    enabled: enabled,
    readOnly: readOnly,
    width: width,
  );
}

_StoryConfiguration _configuration(_Scenario scenario) => switch (scenario) {
  _Scenario.ready => _StoryConfiguration(staticEffectsProvider()),
  _Scenario.selectors => _StoryConfiguration(selectorRichEffectsProvider()),
  _Scenario.loading => _StoryConfiguration(
    staticEffectsProvider(),
    fixedSource(
      SearchSourceSnapshot.loading(
        nodes: effectNames.take(5).map(storyResultNode).toList(),
      ),
    ),
  ),
  _Scenario.partialError => _StoryConfiguration(
    staticEffectsProvider(),
    fixedSource(
      readyStorySnapshot(
        errors: const [
          SearchErrorSummary(
            id: "realmUnavailable",
            message: "Realm results are unavailable. Static results remain.",
            severity: SearchErrorSeverity.warning,
            sourceLabel: "Realm",
          ),
        ],
      ),
    ),
  ),
  _Scenario.empty => _StoryConfiguration(
    staticEffectsProvider(),
    fixedSource(SearchSourceSnapshot.ready(nodes: const [])),
  ),
  _Scenario.history => _StoryConfiguration(historyEffectsProvider()),
  _Scenario.globalLimit => _StoryConfiguration(globallyLimitedComposition()),
  _Scenario.localLimits => _StoryConfiguration(locallyLimitedComposition()),
};

class _StoryConfiguration {
  const _StoryConfiguration(this.provider, [this.sourceBuilder]);

  final SearchProvider provider;
  final PresentationSearchSourceBuilder? sourceBuilder;
}
