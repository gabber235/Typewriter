import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Inline and fallback", type: EditorCommitPlacement)
Widget editorCommitPlacementStory(BuildContext context) =>
    const FakeApp(child: _CommitPlacementStory());

class _CommitPlacementStory extends StatefulWidget {
  const _CommitPlacementStory();

  @override
  State<_CommitPlacementStory> createState() => _CommitPlacementStoryState();
}

class _CommitPlacementStoryState extends State<_CommitPlacementStory> {
  late final TransactionalEditorSource owner;
  bool inline = true;

  @override
  void initState() {
    super.initState();
    owner = TransactionalEditorSource(
      commitPolicy: EditorCommitPolicy.applyResource,
      document: const EditorDocument(
        rootType: StringType(),
        typeCatalog: TypeCatalog([]),
        confirmedValue: StringValue("paper@*"),
        revision: 1,
      ),
      commit: (change) async => MutationSuccess(
        revision: change.expectedRevision + 1,
        value: change.rootValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text("Place actions inside configuration"),
              value: inline,
              onChanged: (value) => setState(() => inline = value),
            ),
            ComposedEditor(
              model: PresentationModel(
                catalog: const TypeCatalog([]),
                inputs: {const BindingId(7): PresentationInput.edit(owner)},
                ownerLabels: {owner: "Configuration"},
                root: PresentationNode(
                  id: "configuration",
                  element: ColumnElement(
                    children: [
                      PresentationAxisChild.fixed(
                        PresentationNode(
                          id: "target",
                          element: TextInputElement(
                            control: BoundControl(
                              binding: const BindingReference(
                                bindingId: BindingId(7),
                              ),
                              label: "Engine target".asStringLiteral,
                            ),
                          ),
                        ),
                      ),
                      PresentationAxisChild.fixed(
                        PresentationNode(
                          id: "placement",
                          element: ConditionalElement(
                            condition: inline.asBooleanLiteral,
                            whenTrue: const PresentationNode(
                              id: "commit",
                              element: CommitControlsElement(
                                binding: BindingReference(
                                  bindingId: BindingId(7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      PresentationAxisChild.fixed(
                        PresentationNode(
                          id: "following",
                          element: TextElement(
                            "Content after configuration".asStringLiteral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    owner.dispose();
    super.dispose();
  }
}
