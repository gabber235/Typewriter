import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The choices of a reference field: a compatible page, an incompatible one
/// with its reason, and creating a new target.
@widgetbook.UseCase(name: "Reference choices", type: ReferencePickerCandidate)
Widget referencePickerUseCase(BuildContext context) {
  final incompatible = context.knobs.boolean(
    label: "Incompatible destination",
    initialValue: true,
  );
  final allowCreate = context.knobs.boolean(
    label: "Allow target creation",
    initialValue: true,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
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

/// Creating an Entry whose required Page and Book the user picks or creates
/// on the way, in a Realm that already holds a compatible Page or none.
@widgetbook.UseCase(
  name: "Required reference creation",
  type: ResourceCreationSession,
)
Widget resourceCreationFlowUseCase(BuildContext context) {
  final existing = context.knobs.boolean(label: "Compatible current page");
  return Story([
    signedIn(ada, organization: acme),
    realmServing(_creation.document(existing: existing)),
  ], at: PanelLocation.component(_CreateEntry(existing: existing)));
}

final _creation = ResourceCreationFixture();

class _CreateEntry extends HookConsumerWidget {
  const _CreateEntry({required this.existing});

  /// Whether the Entry starts from the Realm's compatible Page.
  final bool existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);
    Future<void> create() async {
      busy.value = true;
      try {
        await ref
            .read(resourceCreationProvider(_scope))
            .create(
              context: context,
              request: _creation.request("Entry"),
              creationContext: CreationContext(
                preferredResources: [if (existing) _creation.page],
              ),
            );
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    return FilledButton(
      onPressed: busy.value ? null : create,
      child: const Text("Create Entry"),
    );
  }
}

/// The Realm the story's world seeds.
final _scope = AuthoringScope(
  organizationId: acme.organizationId,
  realmId: skir.recordId("realm_instance:main"),
);
