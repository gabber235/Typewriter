import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "realm_work_toolbar_story_fixture.dart";

@widgetbook.UseCase(name: "Idle with saved Page status", type: RealmWorkToolbar)
Widget realmPublicationIdleUseCase(BuildContext context) =>
    _story(context, RealmWorkToolbarScenario.idle);
@widgetbook.UseCase(name: "Active publication", type: RealmWorkToolbar)
Widget realmPublicationActiveUseCase(BuildContext context) =>
    _story(context, RealmWorkToolbarScenario.active);
@widgetbook.UseCase(name: "Blocked with findings", type: RealmWorkToolbar)
Widget realmPublicationBlockedUseCase(BuildContext context) =>
    _story(context, RealmWorkToolbarScenario.blocked);
@widgetbook.UseCase(name: "Interrupted publication", type: RealmWorkToolbar)
Widget realmPublicationInterruptedUseCase(BuildContext context) =>
    _story(context, RealmWorkToolbarScenario.interrupted);
@widgetbook.UseCase(
  name: "Pending draft and saved publication",
  type: RealmWorkToolbar,
)
Widget realmPublicationPendingDraftUseCase(BuildContext context) =>
    _story(context, RealmWorkToolbarScenario.pendingDraft);

Widget _story(BuildContext context, RealmWorkToolbarScenario scenario) =>
    RealmWorkToolbarStory(
      scenario: scenario,
      width: context.knobs.double.slider(
        label: "Toolbar width",
        initialValue: 720,
        min: 480,
        max: 1000,
      ),
    );

final class RealmWorkToolbarStory extends StatefulWidget {
  const RealmWorkToolbarStory({
    required this.scenario,
    this.fixture,
    this.width = 720,
    super.key,
  });
  final RealmWorkToolbarScenario scenario;
  final RealmWorkToolbarStoryFixture? fixture;
  final double width;
  @override
  State<RealmWorkToolbarStory> createState() => _RealmWorkToolbarStoryState();
}

final class _RealmWorkToolbarStoryState extends State<RealmWorkToolbarStory> {
  late final _fixture =
      widget.fixture ?? RealmWorkToolbarStoryFixture(widget.scenario);
  @override
  void dispose() {
    if (widget.fixture == null) _fixture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FakeApp(
    overrides: [
      localWorkScopeProvider.overrideWithValue(
        LocalWorkScope(
          userId: "toolbar_story",
          organizationId: _fixture.scope.organizationId,
        ),
      ),
      realmPublicationRepositoryProvider(
        _fixture.scope.organizationId,
        _fixture.scope.realmId,
      ).overrideWithValue(_fixture.repository),
    ],
    child: SizedBox(
      width: widget.width,
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _fixture.workspace,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RealmWorkToolbar(
                workspace: _fixture.workspace,
                scope: _fixture.scope,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Saved Page name: ${_fixture.savedName}"),
                    Text("Working Page name: ${_fixture.workingName}"),
                  ],
                ),
              ),
              for (final group in _fixture.workspace.state.groups.values)
                AuthoringGroupControls(
                  workspace: _fixture.workspace,
                  group: group,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
