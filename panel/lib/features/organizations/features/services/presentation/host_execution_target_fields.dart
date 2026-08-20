part of "host_execution_inspector.dart";

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.error,
    ),
  );
}

class _EngineTargetFields extends StatelessWidget {
  const _EngineTargetFields({
    required this.label,
    required this.engines,
    required this.engineId,
    required this.major,
    required this.onEngineChanged,
    required this.onMajorChanged,
  });

  final String label;
  final List<skir.SupportedEngine> engines;
  final String engineId;
  final int major;
  final ValueChanged<String> onEngineChanged;
  final ValueChanged<int> onMajorChanged;

  @override
  Widget build(BuildContext context) {
    final versions = engines
        .firstWhere((engine) => engine.engineId == engineId)
        .supportedMajorVersions;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: engineId,
            decoration: InputDecoration(labelText: label),
            items: [
              for (final engine in engines)
                DropdownMenuItem(
                  value: engine.engineId,
                  child: Text(engine.engineId.formatted),
                ),
            ],
            onChanged: (value) => onEngineChanged(value!),
          ),
        ),
        SizedBox(width: context.spacing.space2),
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<int>(
            initialValue: major,
            decoration: const InputDecoration(labelText: "Major"),
            items: [
              for (final version in versions)
                DropdownMenuItem(value: version, child: Text("$version.x")),
            ],
            onChanged: (value) => onMajorChanged(value!),
          ),
        ),
      ],
    );
  }
}
