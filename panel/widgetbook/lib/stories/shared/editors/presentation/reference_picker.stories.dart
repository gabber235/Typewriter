import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Reference choices", type: SearchModal)
Widget referencePickerUseCase(BuildContext context) {
  final incompatible = context.knobs.boolean(
    label: "Incompatible destination",
    initialValue: true,
  );
  final allowCreate = context.knobs.boolean(
    label: "Allow target creation",
    initialValue: true,
  );
  return FakeApp(
    child: Center(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () => showReferencePicker<String>(
            context,
            candidates: [
              const ReferencePickerCandidate(
                id: "welcome",
                value: "welcome",
                label: "Welcome",
                description: "Sequence page in Tutorial",
              ),
              if (incompatible)
                const ReferencePickerCandidate(
                  id: "static",
                  value: "static",
                  label: "Overview",
                  description: "Static page in Tutorial",
                  disabledReason: "This page does not accept a sequence entry",
                ),
              if (allowCreate)
                const ReferencePickerCandidate(
                  id: "create",
                  value: "create",
                  label: "Create Sequence",
                  description: "Resolve its required references before saving",
                ),
            ],
          ),
          child: const Text("Choose a reference"),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Required reference creation", type: SearchModal)
Widget resourceCreationFlowUseCase(BuildContext context) {
  final existing = context.knobs.boolean(
    label: "Compatible current page",
    initialValue: false,
  );
  return HookBuilder(
    key: ValueKey(existing),
    builder: (context) {
      final fixture = useMemoized(ResourceCreationFixture.new, [existing]);
      final initial = useMemoized(() => fixture.document(existing: existing), [
        fixture,
      ]);
      final transport = useMemoized(
        () => ScriptedAuthoringTransport(AsyncData(initial)),
        [initial],
      );
      useEffect(() => transport.dispose, [transport]);
      final busy = useState(false);
      final outcome = useState<String?>(null);
      final scope = AuthoringScope(
        organizationId: skir.recordId("organization:test"),
        realmId: skir.recordId("realm:test"),
      );
      return FakeApp(
        overrides: [
          organizationIdProvider.overrideWith((_) => scope.organizationId),
          realmIdProvider.overrideWith((_) => scope.realmId),
          ...authoringFixtureOverrides(document: initial, transport: transport),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final document =
                ref.watch(workingAuthoringDocumentProvider(scope)).value ??
                initial;
            return Center(
              child: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Text(
                      existing
                          ? "Use the compatible current page"
                          : "Create an entry, its page and its Book",
                    ),
                    const Text(
                      "Choose existing references or create their targets. Back returns to the previous choice. Cancel any prompt to discard the creation.",
                    ),
                    FilledButton(
                      onPressed: busy.value
                          ? null
                          : () async {
                              busy.value = true;
                              outcome.value = null;
                              try {
                                final created = await ref
                                    .read(resourceCreationProvider(scope))
                                    .create(
                                      context: context,
                                      request: fixture.request("Entry"),
                                      creationContext: CreationContext(
                                        preferredResources: [
                                          if (existing) fixture.page,
                                        ],
                                      ),
                                    );
                                if (context.mounted) {
                                  outcome.value = created == null
                                      ? "Creation cancelled"
                                      : "Entry created";
                                }
                              } on Object catch (error) {
                                if (context.mounted) {
                                  outcome.value = error.toString();
                                }
                              } finally {
                                if (context.mounted) busy.value = false;
                              }
                            },
                      child: Text(
                        busy.value ? "Resolving references" : "Begin creation",
                      ),
                    ),
                    if (outcome.value case final message?) Text(message),
                    Text("Resources: ${document.entries.length}"),
                    for (final entry in document.entries.values)
                      Text(
                        document.catalog.typeSelectionName(
                          entry.content.configuration,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
