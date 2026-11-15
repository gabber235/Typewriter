import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

final _builder = role("builder", name: "Builder");
final _moderator = role("moderator", name: "Moderator");

/// A member in the primary search: their name, the roles they hold or No
/// roles, and the shortcut that opens them.
@widgetbook.UseCase(name: "Default", type: MemberSearchResultItem)
Widget memberSearchResultItemUseCase(BuildContext context) {
  final roles = context.knobs.object.segmented(
    label: "Roles",
    options: const ["Two", "None"],
    initialOption: "Two",
  );
  final grace = member(
    "Grace Hopper",
    email: "grace@example.com",
    roles: roles == "Two" ? [_builder, _moderator] : const [],
  );
  return _row(
    context,
    (state) => MemberSearchResultItem(
      member: grace,
      row: storyRowContext(
        memberSearchResultType,
        grace,
        title: grace.searchTitle,
        state: state,
      ),
    ),
  );
}

/// A join code in the primary search: the roles it grants or Needs
/// approval, and whether it works once or many times.
@widgetbook.UseCase(name: "Default", type: JoinCodeSearchResultItem)
Widget joinCodeSearchResultItemUseCase(BuildContext context) {
  final approval = context.knobs.boolean(label: "Needs approval");
  final singleUse = context.knobs.boolean(label: "Single-use");
  final item = JoinCodeSearchItem(
    code: joinCode(
      "invite",
      singleUse: singleUse,
      roles: approval ? const [] : [_builder.roleId],
    ),
    roles: approval ? const [] : [_builder],
  );
  return _row(
    context,
    (state) => JoinCodeSearchResultItem(
      code: item,
      row: storyRowContext(
        joinCodeSearchResultType,
        item,
        title: joinCodeSearchResultType.label,
        state: state,
      ),
    ),
  );
}

/// A pending join request in the primary search: who asks, over their
/// email, or Waiting for approval when only the email is known.
@widgetbook.UseCase(name: "Default", type: JoinRequestSearchResultItem)
Widget joinRequestSearchResultItemUseCase(BuildContext context) {
  final named = context.knobs.boolean(label: "Name known", initialValue: true);
  final request = joinRequest(
    "linus",
    name: named ? "Linus Torvalds" : null,
    email: "linus@example.com",
  );
  return _row(
    context,
    (state) => JoinRequestSearchResultItem(
      request: request,
      row: storyRowContext(
        joinRequestSearchResultType,
        request,
        title: request.searchTitle,
        state: state,
      ),
    ),
  );
}

Widget _row(BuildContext context, Widget Function(String state) item) {
  final state = context.knobs.object.segmented(
    label: "Row",
    options: storyRowStates,
    initialOption: storyRowStates.first,
  );
  final width = context.knobs.width(const {"Wide": 560, "Narrow": 280});
  return Story(
    const [],
    at: PanelLocation.component(SizedBox(width: width, child: item(state))),
  );
}
