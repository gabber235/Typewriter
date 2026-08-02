import "package:flutter/material.dart" hide Title;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TagHeader extends HookConsumerWidget {
  const TagHeader({required this.tag, super.key});

  final Tag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagColor = tag.color.toARGB32() != 0
        ? tag.color
        : context.colors.contentDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: tag.name.formatted, color: tagColor),
        SizedBox(height: context.spacing.space2),
        Identifier(id: tag.tagId.id),
      ],
    );
  }
}
