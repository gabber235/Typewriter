import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ControlsShowcase extends StatelessWidget {
  const ControlsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return SizedBox(
      width: 1200,
      height: 900,
      child: Padding(
        padding: EdgeInsets.all(spacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Controls", style: Theme.of(context).textTheme.headlineLarge),
            SizedBox(height: spacing.space6),
            Wrap(
              spacing: spacing.space3,
              runSpacing: spacing.space3,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text("Elevated")),
                ElevatedButton(onPressed: null, child: const Text("Disabled")),
                FilledButton(onPressed: () {}, child: const Text("Filled")),
                OutlinedButton(onPressed: () {}, child: const Text("Outlined")),
                TextButton(onPressed: () {}, child: const Text("Text")),
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
            ),
            SizedBox(height: spacing.space6),
            const SizedBox(
              width: 420,
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Label",
                  hintText: "Input hint",
                ),
              ),
            ),
            SizedBox(height: spacing.space4),
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                Switch(value: true, onChanged: (_) {}),
              ],
            ),
            SizedBox(height: spacing.space4),
            Wrap(
              spacing: spacing.space2,
              children: const [
                Chip(label: Text("Default")),
                InputChip(label: Text("Selected"), selected: true),
                Chip(label: Text("Disabled")),
              ],
            ),
            SizedBox(height: spacing.space6),
            Card(
              child: Padding(
                padding: EdgeInsets.all(spacing.space4),
                child: const Text("Card and surface hierarchy"),
              ),
            ),
            SizedBox(height: spacing.space4),
            Row(
              children: [
                const CircularProgressIndicator(value: 0.65),
                SizedBox(width: spacing.space6),
                const Expanded(child: LinearProgressIndicator(value: 0.65)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
