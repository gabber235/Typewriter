import "package:flutter/material.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/routes/organization/book/page/route.dart";
import "package:typewriter_panel/routes/organization/book/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

Widget _buildPagePageUseCase(
  BuildContext context,
  PageType pageType, {
  List<PageElement>? ovewriteElements,
}) {
  final pagesState = context.knobs.displayState(
    label: "Pages State",
    initialOption: DisplayState.manyItems,
  );
  final entriesState = context.knobs.displayState(
    label: "Entries State",
    initialOption: DisplayState.manyItems,
  );

  final servicesState = context.knobs.displayState(
    label: "Services State",
    initialOption: DisplayState.manyItems,
  );

  return FakeApp(
    overrides: [
      ...entryProviderOverrides(),
      ...pageElementsProviderOverrides(
        state: entriesState,
        pageType: pageType,
        overwriteElements: ovewriteElements,
      ),
      ...bookPagesProviderOverrides(state: pagesState),
      ...pagesProviderOverrides(pageType: pageType),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: pagesState),
      ...servicesProviderOverrides(state: servicesState),
      ...realmProviderOverrides(),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(child: PagePage(pageId: "example-page-id")),
  );
}

@widgetbook.UseCase(name: "Sequence", type: PagePage)
Widget pagePageSequenceUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_SEQUENCE);
}

@widgetbook.UseCase(name: "Static", type: PagePage)
Widget pagePageStaticUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_STATIC);
}

@widgetbook.UseCase(name: "Scene", type: PagePage)
Widget pagePageSceneUseCase(BuildContext context) {
  final demoScene = sceneElements()
      .entry(
        id: "entry_npc",
        name: "Entity",
        color: Colors.pinkAccent,
        children: [
          .segment(
            "NPC",
            start: 0,
            end: 50,
            color: Colors.pinkAccent,
            children: [
              for (var i = 0; i < 50; i += 2)
                .keyframe("$i", frame: i, color: Colors.pinkAccent.shade100),
              .segment(
                "Equipment",
                start: 10,
                end: 30,
                color: Colors.pink.shade200,
              ),
              .segment(
                "Sneaking",
                start: 20,
                end: 40,
                color: Colors.pink.shade300,
              ),
            ],
          ),
        ],
      )
      .entry(
        id: "entry_dialogue",
        name: "Dialogue",
        color: Colors.greenAccent,
        children: [
          .segment(
            "Winston Dialogue",
            start: 0,
            end: 130,
            color: Colors.greenAccent,
            children: [
              .segment(
                "So...",
                start: 0,
                end: 30,
                color: Colors.greenAccent.shade100,
              ),
              .segment(
                "You like the new features?",
                start: 50,
                end: 110,
                color: Colors.greenAccent.shade100,
              ),
            ],
          ),
          .segment("Player Dialogue", start: 131, end: 200, color: Colors.greenAccent)
        ],
      )
      .entry(
        id: "entry_game_time",
        name: "Game Time",
        color: Colors.redAccent,
        children: [
          .segment(
            "Time Distortion",
            start: 0,
            end: 99,
            color: Colors.redAccent,
            children: [
              .segment(
                "Forward Animation",
                start: 0,
                end: 30,
                color: Colors.redAccent.shade100,
              ),
              .segment(
                "Reverse Animation",
                start: 70,
                end: 99,
                color: Colors.redAccent.shade100,
              ),
            ],
          ),
        ],
      )
      .entry(
        id: "world_border",
        name: "World Border",
        color: Colors.yellowAccent,
        children: [
          .segment(
            "Border",
            start: 120,
            end: 180,
            color: Colors.yellowAccent,
            children: [
            .segment("Move Closer", start: 0, end: 20, color: Colors.yellowAccent.shade100),
            .segment("Move Farther", start: 45, end: 60, color: Colors.yellowAccent.shade100),
           ],
          ),
        ],
      )
      .entry(
        id: "entry_camera",
        name: "Camera",
        color: Colors.blueAccent,
        children: [
          .segment(
            "Close up",
            start: 0,
            end: 99,
            color: Colors.blueAccent,
            children: [
              .segment(
                "Zoom in",
                start: 0,
                end: 29,
                color: Colors.blueAccent.shade100,
              ),
              .segment(
                "Move sideways",
                start: 30,
                end: 70,
                color: Colors.blueAccent.shade100,
              ),
              .segment(
                "Zoom out",
                start: 71,
                end: 99,
                color: Colors.blueAccent.shade100,
              ),
            ],
          ),
          .segment(
            "Wide angle",
            start: 100,
            end: 199,
            color: Colors.blueAccent,
            children: [
              .segment(
                "Slide right",
                start: 0,
                end: 99,
                color: Colors.blueAccent.shade100,
              ),
            ],
          ),
        ],
      )
      .build();

  return _buildPagePageUseCase(
    context,
    PageType.PAGE_TYPE_SCENE,
    ovewriteElements: demoScene,
  );
}

@widgetbook.UseCase(name: "Manifest", type: PagePage)
Widget pagePageManifestUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_MANIFEST);
}
