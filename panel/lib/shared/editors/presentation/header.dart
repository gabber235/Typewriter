import "package:flutter/material.dart";

class Header extends StatelessWidget {
  const Header({required this.title, this.description, super.key});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (description case final value?) Text(value),
    ],
  );
}
