import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

typedef SemanticHeaderScenario = ({
  TypeExpression type,
  DataValue value,
  PresentationNode? presentation,
  String description,
});

class SemanticHeaderGallery extends StatelessWidget {
  const SemanticHeaderGallery({
    required this.scenario,
    required this.width,
    this.readOnly = false,
    super.key,
  });

  final SemanticHeaderScenario scenario;
  final double width;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => FakeApp(
    child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Section(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      scenario.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    EditorProtocolRenderer(
                      envelope: TypedValueEnvelope(
                        rootType: _storyRoot,
                        rootValue: scenario.value,
                      ),
                      typeCatalog: TypeCatalog([
                        TypeDefinition(
                          id: _storyRoot,
                          kind: NominalTypeKind.concrete,
                          representation: scenario.type,
                        ),
                      ]),
                      presentation: scenario.presentation,
                      readOnly: readOnly,
                    ),
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

final _storyRoot = ResolvedTypeRef(
  id: const QualifiedTypeId(namespace: "widgetbook", name: "HeaderStory"),
  revision: 1,
);
