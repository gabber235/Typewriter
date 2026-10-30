import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The copy of a resource card the user drags, still carrying what its last
/// operation reported.
@widgetbook.UseCase(name: "Dragged card", type: PortableDiagnosticPreview)
Widget diagnosticPreviewUseCase(BuildContext context) {
  final outcome = context.knobs.object.segmented(
    label: "Last operation",
    options: const ["Failed", "Saved"],
    initialOption: "Failed",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      _DraggedCard(key: ValueKey(outcome), failed: outcome == "Failed"),
    ),
  );
}

class _DraggedCard extends HookWidget {
  const _DraggedCard({required this.failed, super.key});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() {
      unawaited(
        operations.run(
          key: const PortableOperationKey.status(),
          operation: () => failed
              ? PortablePresentationWriteResult.rejected([
                  PortablePresentationDiagnostic(
                    code: "move_rejected",
                    message: "Village Market cannot move into a Scene",
                    severity: skir.DiagnosticSeverity.error,
                  ),
                ])
              : const PortablePresentationWriteResult.applied(),
        ),
      );
      return operations.dispose;
    }, [operations]);
    return PortableDiagnosticPreview(
      operations: operations,
      child: SizedBox(
        width: 280,
        child: PortablePresentationChrome(
          role: skir.PresentationRole.resourceSearchResult,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: const Text("Village Market"),
            ),
          ),
        ),
      ),
    );
  }
}
