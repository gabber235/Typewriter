import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/authored_resource_editor.stories.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Creation type picker", type: AuthoredResourceEditor)
Widget authoredTypePickerUseCase(BuildContext context) {
  return Story(const [], at: PanelLocation.component(const _PagePicker()));
}

/// Asks for the concrete page type of a new page as soon as it shows, the
/// way creating a page asks.
class _PagePicker extends HookWidget {
  const _PagePicker();

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      final message = messageFixture();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        unawaited(
          showCreationConcreteTypePicker(
            context,
            expected: skir.TypeSelection(
              definition: message.page,
              arguments: const [],
            ),
            catalog: message.catalog,
          ),
        );
      });
      return null;
    }, const []);
    return const SizedBox.shrink();
  }
}
