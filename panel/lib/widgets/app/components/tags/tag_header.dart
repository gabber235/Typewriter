import "package:flutter/material.dart" hide Title;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";

class TagHeader extends HookConsumerWidget {
  const TagHeader({required this.tag, super.key});

  final Tag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagColor = tag.color.value != 0
        ? Color(tag.color.value)
        : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: tag.name.formatted, color: tagColor),
        const SizedBox(height: 8),
        Identifier(id: tag.tagId),
      ],
    );
  }
}
