import "package:flutter/material.dart";

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, super.key}) : super();
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 14),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
