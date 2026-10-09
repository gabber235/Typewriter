import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoringSubjectRole extends ConsumerWidget {
  const AuthoringSubjectRole({
    required this.resourceId,
    required this.role,
    this.fillAvailableSpace = false,
    super.key,
  });

  final skir.ResourceId resourceId;
  final skir.PresentationRole role;
  final bool fillAvailableSpace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(selectedWorkingAuthoringDocumentProvider);
    final document = source.value;
    if (document == null) {
      return source.isLoading
          ? ShimmerBox.rectangle(width: double.infinity, height: 20)
          : const _UnavailableRole();
    }
    return AuthoredResourceEditor(
      resource: resourceId,
      document: document,
      role: role,
      fillAvailableSpace: fillAvailableSpace,
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
      enabled: false,
    );
  }
}

final class _UnavailableRole extends StatelessWidget {
  const _UnavailableRole();

  @override
  Widget build(BuildContext context) => const Tooltip(
    message: "Resource presentation is unavailable",
    child: Icon(Icons.warning_rounded, size: 14),
  );
}
