import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: TagNode)
Widget tagNodeUseCase(BuildContext context) {
  final previewTag = generateRandomTag();

  return FakeApp(
    overrides: [
      ...tagsProviderOverrides(tags: [previewTag]),
    ],
    child: Center(
      child: SizedBox(
        width: 150,
        height: 50,
        child: TagNode(tagId: previewTag.tagId),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Multiple Colors", type: TagNode)
Widget tagNodeColorsUseCase(BuildContext context) {
  final colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  final tags = colors.asMap().entries.map((entry) {
    return Tag(
      tagId: "tag-${entry.key}",
      name: "tag_${entry.key}",
      color: entry.value.toProtoColor(),
    );
  }).toList();

  return FakeApp(
    overrides: [...tagsProviderOverrides(tags: tags)],
    child: Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: tags.map((tag) {
          return SizedBox(
            width: 120,
            height: 40,
            child: TagNode(tagId: tag.tagId),
          );
        }).toList(),
      ),
    ),
  );
}
