import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The resources an operation story selects, in selection order.
const _resources = ["Meet the Mayor", "Village Market", "Lost Lantern"];

/// What the operation does to each selected resource.
enum OperationOutcome {
  /// Every resource completes the operation.
  succeeds,

  /// The last resource refuses the operation.
  partlyFails,
}

/// The inspector operations of [count] selected resources, each offering
/// the capability [capability] builds around the outcome its knobs chose.
///
/// The resources start selected, so the inspector buttons, holds and
/// refusals are the production ones.
Widget operationStory(
  BuildContext context,
  SelectionCapability Function(Future<void> Function() run) capability,
) {
  final count = context.knobs.int.slider(
    label: "Selected resources",
    initialValue: 1,
    min: 1,
    max: _resources.length,
  );
  final outcome = context.knobs.object.segmented(
    label: "Outcome",
    options: OperationOutcome.values,
    labelBuilder: (value) => value.name.formatted,
    initialOption: OperationOutcome.succeeds,
  );
  final selection = [
    for (final (index, name) in _resources.take(count).indexed)
      OperationStorySelectable(
        name,
        capability(() async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (outcome == OperationOutcome.partlyFails && index == count - 1) {
            throw ApiException(
              code: 409,
              message: "$name is still used by another page",
            );
          }
        }),
      ),
  ];
  return Story(
    [selected(selection)],
    at: const PanelLocation.component(
      SizedBox(width: 320, child: InspectorOperations()),
    ),
  );
}

/// A selectable resource named [name] that offers [capability].
final class OperationStorySelectable extends SelectableIdentifier {
  const OperationStorySelectable(this.name, this.capability);

  final String name;
  final SelectionCapability capability;

  @override
  String get id => name.snakeCase();

  @override
  AsyncValue<Selectable> create(Ref ref) =>
      AsyncData(_OperationSelectable(this));

  @override
  bool operator ==(Object other) =>
      other is OperationStorySelectable && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class _OperationSelectable
    extends InspectableSelectable<OperationStorySelectable> {
  const _OperationSelectable(this.id);

  @override
  final OperationStorySelectable id;

  @override
  String get name => id.name;

  @override
  List<SelectionCapability> get capabilities => [id.capability];

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) =>
      InspectionContent(body: const SizedBox.shrink());
}
