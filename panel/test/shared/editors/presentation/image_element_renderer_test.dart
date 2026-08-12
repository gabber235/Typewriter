import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("clips image content with rounded corners", (tester) async {
    await tester.pumpTestApp(child: _renderer(), settle: false);

    final clip = tester.widget<ClipRRect>(
      find.ancestor(of: find.byType(Image), matching: find.byType(ClipRRect)),
    );

    expect(clip.borderRadius, BorderRadius.circular(8));
  });

  testWidgets("shows shimmer until the first image frame loads", (
    tester,
  ) async {
    await tester.pumpTestApp(child: _renderer(), settle: false);

    final image = tester.widget<Image>(find.byType(Image));
    final imageContext = tester.element(find.byType(Image));
    const loadedImage = SizedBox(key: ValueKey("loadedImage"));

    final loading = image.frameBuilder!(imageContext, loadedImage, null, false);
    final loaded = image.frameBuilder!(imageContext, loadedImage, 0, false);

    expect(loading, isA<ShimmerBox>());
    expect(loaded, same(loadedImage));
  });
}

EditorProtocolRenderer _renderer() {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "root"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: root,
      rootValue: const StringValue("value"),
    ),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: const StringType(),
      ),
    ]),
    presentation: PresentationNode(
      id: "image",
      element: ImageElement(
        source: "https://example.com/image.png".asStringLiteral,
      ),
    ),
  );
}
