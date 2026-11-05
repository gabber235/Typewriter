import "package:typewriter_panel/typewriter_panel.dart";

/// A 360 wide dropdown on "Alpha" with a disabled "Unavailable" and a "Beta"
/// choice, driven by [controller], followed by a "Next control" button; a
/// choice the user picks becomes the selection.
final class ChoiceDropdown extends StatelessWidget {
  const ChoiceDropdown(this.controller, {super.key});

  final InputFieldController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: HookBuilder(
        builder: (context) {
          final selected = useState("alpha");
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Dropdown<String>(
                inputFieldController: controller,
                selected: selected.value,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: "alpha", label: "Alpha"),
                  DropdownMenuEntry(
                    value: "unavailable",
                    label: "Unavailable",
                    enabled: false,
                  ),
                  DropdownMenuEntry(value: "beta", label: "Beta"),
                ],
                onSelected: (value) {
                  if (value != null) selected.value = value;
                },
              ),
              TextButton(onPressed: () {}, child: const Text("Next control")),
            ],
          );
        },
      ),
    );
  }
}
