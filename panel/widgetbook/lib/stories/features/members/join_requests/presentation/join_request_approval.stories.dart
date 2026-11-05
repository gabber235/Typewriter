import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: JoinRequestApproval)
Widget joinRequestApprovalUseCase(BuildContext context) {
  final roles = context.knobs.object.dropdown(
    label: "Roles",
    options: const ["Ready", "Loading", "Failing"],
    initialOption: "Ready",
  );
  final picked = context.knobs.boolean(label: "Role picked");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 480,
        child: _Approval(
          request: storyJoinRequests(Generator(context.knobs.seed()), 1).single,
          roles: switch (roles) {
            "Loading" => const AsyncLoading(),
            "Failing" => AsyncError(
              StateError("The membership service is unreachable"),
              StackTrace.empty,
            ),
            _ => AsyncData(storyRoles),
          },
          picked: picked,
        ),
      ),
    ),
  );
}

/// Keeps the picked roles and approves after a short wait, as the join
/// request card does.
class _Approval extends HookWidget {
  const _Approval({
    required this.request,
    required this.roles,
    required this.picked,
  });

  final skir.OrganizationJoinRequest request;
  final AsyncValue<List<skir.OrganizationRole>> roles;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final selected = useState<List<skir.OrganizationRole>>(
      picked ? [storyRoles[3]] : const [],
    );
    return JoinRequestApproval(
      request: request,
      selectedRoles: selected.value,
      rolesAsync: roles,
      onRolesChanged: (roles) => selected.value = roles,
      onConfirm: () => Future<void>.delayed(const Duration(seconds: 2)),
    );
  }
}
