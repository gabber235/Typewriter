import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The stacked body of a join request card on smaller windows: who asked,
/// when the request expires, then Decline, which holds, beside Accept, which
/// turns into Cancel once pressed.
@widgetbook.UseCase(name: "Default", type: JoinRequestResponsiveContent)
Widget joinRequestResponsiveContentUseCase(BuildContext context) {
  final longName = context.knobs.boolean(label: "Long name, expiring");
  final selected = context.knobs.boolean(label: "Selected");
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 360,
    min: 260,
    max: 640,
  );
  final request = storyJoinRequests(Generator(1), 2)[longName ? 1 : 0];
  return Story(
    [
      membership(roles: storyRoles, joinRequests: [request]),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: StoryRows(
          items: [request],
          identity: (request) => request.requestId,
          builder: (context, selection) => _Content(
            request: request,
            selected: selected,
            rows: selection.rows,
          ),
        ),
      ),
    ),
  );
}

/// Keeps whether Accept was pressed, as the card's expansion does.
class _Content extends HookWidget {
  const _Content({
    required this.request,
    required this.selected,
    required this.rows,
  });

  final skir.OrganizationJoinRequest request;
  final bool selected;
  final AnimatedRows<Object?> rows;

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);
    return JoinRequestResponsiveContent(
      request: request,
      isSelected: selected,
      isExpanded: expanded.value,
      onExpired: () {},
      decline: joinRequestDecline(
        id: "story_decline_join_request",
        label: "Decline",
        targets: () => {request.requestId},
        nameOf: (_) => request.userName,
        rows: rows,
      ),
      onToggle: () => expanded.value = !expanded.value,
    );
  }
}
