import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Independent inputs", type: ComposedEditor)
Widget composedEditorUseCase(BuildContext context) =>
    const FakeApp(child: _CompositionStory());

class _CompositionStory extends StatefulWidget {
  const _CompositionStory();

  @override
  State<_CompositionStory> createState() => _CompositionStoryState();
}

class _CompositionStoryState extends State<_CompositionStory> {
  late final TransactionalEditorSource identity;
  late final TransactionalEditorSource configuration;
  bool failed = false;
  bool rejectSave = false;
  int reports = 1;
  final type = RecordType(
    fields: const {"value": TypeField(name: "value", type: StringType())},
  );

  @override
  void initState() {
    super.initState();
    identity = _resource("paper_host", 4);
    configuration = _resource("typewritermc:paper@*", 9);
  }

  TransactionalEditorSource _resource(String initial, int revision) =>
      TransactionalEditorSource(
        document: EditorDocument(
          rootType: type,
          typeCatalog: const TypeCatalog([]),
          confirmedValue: RecordValue({"value": StringValue(initial)}),
          revision: revision,
        ),
        commit: (commit) async {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          if (rejectSave) {
            return TypedMutationResult.unavailable([
              const TypeDiagnostic(
                code: TypeDiagnosticCode.invalidValue,
                message: "Service temporarily unavailable",
              ),
            ]);
          }
          return TypedMutationResult.success(
            revision: commit.expectedRevision + 1,
            value: commit.rootValue,
          );
        },
      );

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => setState(() {
                      reports++;
                      failed = !failed;
                    }),
                    child: const Text("Receive runtime report"),
                  ),
                  FilterChip(
                    label: const Text("Reject saves"),
                    selected: rejectSave,
                    onSelected: (value) => setState(() => rejectSave = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ComposedEditor(
                model: PresentationModel(
                  catalog: const TypeCatalog([]),
                  inputs: {
                    const BindingId(4): PresentationInput.edit(identity),
                    const BindingId(8): PresentationInput.edit(configuration),
                    const BindingId(12): PresentationInput.value(
                      type: const StringType(),
                      value: EditorValue.ready(
                        StringValue(
                          "${failed ? "Failed" : "Active"}. Report $reports",
                        ),
                      ),
                    ),
                  },
                  ownerLabels: {
                    identity: "Service identity",
                    configuration: "Host configuration",
                  },
                  root: PresentationNode(
                    id: "composition",
                    element: ColumnElement(
                      spacing: 16,
                      children: [
                        PresentationAxisChild.fixed(
                          _input("identity", 4, "Service name"),
                        ),
                        PresentationAxisChild.fixed(
                          _input("configuration", 8, "Engine target"),
                        ),
                        PresentationAxisChild.fixed(
                          const PresentationNode(
                            id: "runtime",
                            element: TextElement(
                              TypedExpression(
                                resultType: StringType(),
                                expression: BindingExpression(
                                  BindingReference(bindingId: BindingId(12)),
                                ),
                              ),
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
    ),
  );

  PresentationNode _input(String id, int binding, String label) =>
      PresentationNode(
        id: id,
        element: TextInputElement(
          control: BoundControl(
            binding: BindingReference(
              bindingId: BindingId(binding),
              path: DataPath.root.field("value"),
            ),
            label: label.asStringLiteral,
          ),
          multiline: false,
        ),
      );

  @override
  void dispose() {
    identity.dispose();
    configuration.dispose();
    super.dispose();
  }
}
