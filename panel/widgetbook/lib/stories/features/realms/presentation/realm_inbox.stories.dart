import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "realm_inbox_story_fixture.dart";

@widgetbook.UseCase(name: "Live review", type: RealmInboxButton)
Widget realmInboxButtonUseCase(BuildContext context) => _story(context);
@widgetbook.UseCase(name: "Conditional sections", type: RealmInboxView)
Widget realmInboxViewUseCase(BuildContext context) =>
    _story(context, inline: true);
@widgetbook.UseCase(name: "Provider owned review", type: RealmInboxContent)
Widget realmInboxContentUseCase(BuildContext context) =>
    _story(context, inline: true);
@widgetbook.UseCase(name: "Normal mode opening", type: RealmInboxShortcut)
Widget realmInboxShortcutUseCase(BuildContext context) => _story(context);
@widgetbook.UseCase(name: "Realm activity", type: WorkspaceActivityButton)
Widget workspaceActivityUseCase(BuildContext context) => _story(context);

Widget _story(BuildContext context, {bool inline = false}) => RealmInboxStory(
  scenario: context.knobs.object.dropdown(
    label: "Review",
    options: RealmInboxScenario.values,
    initialOption: RealmInboxScenario.ready,
    labelBuilder: (value) => value.name,
  ),
  width: context.knobs.double.slider(
    label: "Surface width",
    initialValue: 760,
    min: 280,
    max: 1200,
  ),
  reducedMotion: context.knobs.boolean(label: "Reduce motion"),
  inline: inline,
);

class RealmInboxStory extends HookWidget {
  const RealmInboxStory({
    this.scenario = RealmInboxScenario.ready,
    this.width = 760,
    this.reducedMotion = false,
    this.inline = false,
    this.fixture,
    super.key,
  });
  final RealmInboxScenario scenario;
  final double width;
  final bool reducedMotion;
  final bool inline;
  final RealmInboxStoryFixture? fixture;
  @override
  Widget build(BuildContext context) {
    final owner = useMemoized(
      () => fixture ?? RealmInboxStoryFixture(scenario),
    );
    useEffect(() => fixture == null ? owner.dispose : null, [owner]);
    useEffect(() {
      owner.select(scenario);
      return null;
    }, [scenario]);
    return FakeApp(
      overrides: [
        selectedAuthoringScopeProvider.overrideWithValue(owner.scope),
        realmInteractionProvider.overrideWithValue(
          const RealmInteractionState(
            connectionState: RealmConnectionState.online,
          ),
        ),
        realmInboxProvider(owner.scope).overrideWith((ref) {
          owner.addListener(ref.invalidateSelf);
          ref.onDispose(() => owner.removeListener(ref.invalidateSelf));
          return owner.state;
        }),
        workingAuthoringDocumentProvider(owner.scope)
            .overrideWith((ref) => AsyncData(owner.document)),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: RealmInboxShortcut(
            child: Focus(
              autofocus: true,
              skipTraversal: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      CustomAppBar(
                        navigation: const Text("Bright Purple Swan"),
                        primary: AppBarItem.adaptive(
                          key: const ValueKey("search"),
                          collapseOrder: 0,
                          child: const PrimarySearchButton(),
                        ),
                        actions: [
                          AppBarItem.adaptive(
                            key: const ValueKey("inbox"),
                            collapseOrder: 1,
                            child: const WorkspaceActivityButton(),
                          ),
                        ],
                      ),
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: () =>
                                owner.select(RealmInboxScenario.blocked),
                            child: const Text("Introduce issue"),
                          ),
                          TextButton(
                            onPressed: () =>
                                owner.select(RealmInboxScenario.ready),
                            child: const Text("Resolve issue"),
                          ),
                          TextButton(
                            onPressed: () =>
                                owner.select(RealmInboxScenario.localDraft),
                            child: const Text("Add draft problem"),
                          ),
                        ],
                      ),
                      if (inline)
                        Expanded(
                          child: Material(
                            child: RealmInboxContent(
                              scope: owner.scope,
                              onClose: () {},
                            ),
                          ),
                        ),
                      if (!inline)
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "Hover to preview. Click or press Shift + P in Normal mode to focus the inbox.",
                              ),
                            ),
                          ),
                        ),
                      const ActionRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
