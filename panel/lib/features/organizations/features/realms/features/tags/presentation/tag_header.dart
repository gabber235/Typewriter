import "package:flutter/material.dart" hide Title;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TagHeader extends HookConsumerWidget {
  const TagHeader({required this.tag, super.key});

  final Tag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagColor = tag.color.value != 0
        ? Color(tag.color.value)
        : context.colors.contentDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: tag.name.formatted, color: tagColor),
        SizedBox(height: context.spacing.space2),
        Identifier(id: tag.tagId),
      ],
    );
  }
}
