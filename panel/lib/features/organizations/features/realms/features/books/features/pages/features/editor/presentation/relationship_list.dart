import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef RelationshipResourceCallback = FutureOr<void> Function(
  RelationshipGroup group,
);
typedef RelationshipUsageCallback = FutureOr<void> Function(
  RelationshipGroup group,
  RelationshipUsage usage,
);
typedef RelationshipSourceFocusCallback = FutureOr<void> Function(
  String sourceId,
  DataPath path,
);
typedef RelationshipGroupBuilder = Widget Function(
  BuildContext context,
  RelationshipGroup group,
);

/// Inspector header that follows the projected page relationship read model.
class EntryInspectorHeader extends ConsumerWidget {
  const EntryInspectorHeader({
    required this.id,
    required this.name,
    required this.color,
    required this.owner,
    super.key,
  });

  final EntryIdentifier id;
  final String name;
  final Color color;
  final EditOwner owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    final pageId = id.pageId;
    final elements = organizationId == null || realmId == null || pageId == null
        ? const <PageElement>[]
        : ref
                  .watch(
                    projectedPageElementsProvider(
                      organizationId,
                      realmId,
                      pageId,
                    ),
                  )
                  .value ??
              const <PageElement>[];
    final relationships = elements.relationshipsFor(id.id);
    final entryTypes = <String, ResolvedTypeRef>{};
    if (id.elementType case final elementType?) {
      entryTypes[id.id] = elementType;
    }
    for (final element in elements) {
      if (element case PageElementEntry(:final entry)) {
        switch (entry) {
          case DefinitionPageEntry(:final definition):
            entryTypes[entry.id] = definition.elementDefinition.rootType;
          case ReferencePageEntry(:final subject):
            entryTypes[entry.id] = subject.content.rootType;
          default:
        }
      }
    }
    final relatedIds = {
      id.id,
      for (final group in relationships.incoming) group.resourceId,
      for (final group in relationships.outgoing) group.resourceId,
    };
    final resources = {
      for (final resourceId in relatedIds)
        skir.ResourceId(value: resourceId): ?entryTypes[resourceId],
    };
    final subjects =
        organizationId == null || realmId == null || resources.isEmpty
        ? null
        : ref.watch(
            authoringSubjectsProvider(
              AuthoringSubjectScope(
                organizationId: organizationId,
                realmId: realmId,
                resources: resources,
              ),
            ),
          );

    void openEntry(String resourceId, String? targetPageId) {
      if (targetPageId == null) return;
      if (ref.read(pageIdProvider)?.id != targetPageId) {
        unawaited(
          ref.read(appRouterProvider).push(RouteRoute(pageId: targetPageId)),
        );
      }
      ref.read(selectionProvider.notifier).selectAll([
        EntryIdentifier(resourceId, pageId: targetPageId),
      ]);
    }

    void open(RelationshipGroup group) =>
        openEntry(group.resourceId, group.pageId ?? pageId);

    String? sourcePage(RelationshipGroup group, RelationshipUsage usage) =>
        usage.sourceId == id.id ? pageId : group.pageId ?? pageId;

    final focusController = ref.watch(renderedBindingFocusControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EntryRoleHeader(id: id, subjects: subjects),
        if (relationships.incoming.isNotEmpty ||
            relationships.outgoing.isNotEmpty) ...[
          const Divider(),
          RelationshipList(
            relationships: relationships,
            onOpenResource: open,
            onOpenUsage: (group, usage) =>
                openEntry(usage.sourceId, sourcePage(group, usage)),
            onFocusSourceField: (sourceId, path) => focusController
                .requestFocus(skir.ResourceId(value: sourceId), path),
            groupBuilder: (context, group) =>
                _RelationshipRoleGroup(group: group, subjects: subjects),
          ),
        ],
      ],
    );
  }
}

class _RelationshipRoleGroup extends StatelessWidget {
  const _RelationshipRoleGroup({required this.group, required this.subjects});

  final RelationshipGroup group;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context) {
    final projection = switch (subjects) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (projection == null) {
      if (subjects?.hasError ?? subjects == null) {
        return presentationDiagnostic(context, [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message:
                "Relationship presentation for element:${group.resourceId} is unavailable",
            pathPresent: false,
          ),
        ]);
      }
      return ShimmerBox.rectangle(width: double.infinity, height: 20);
    }
    final subject =
        projection.subjects[skir.ResourceId(value: group.resourceId)];
    final result = subject == null
        ? null
        : TypedAuthoringCodec(projection.catalog).subjectPresentation(
            subject,
            PresentationRole.referenceSummary,
            collections: projection.collections,
          );
    final resolved = result?.valueOrNull;
    if (resolved == null) {
      final diagnostics = result?.diagnostics.isNotEmpty == true
          ? result!.diagnostics
          : projection.diagnostics;
      if (diagnostics.isEmpty) {
        return presentationDiagnostic(context, [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message:
                "Relationship subject element:${group.resourceId} is unavailable",
            pathPresent: false,
          ),
        ]);
      }
      return presentationDiagnostic(context, diagnostics);
    }
    return IgnorePointer(
      child: ComposedEditor(
        model: resolved.model,
        readOnly: true,
        historyNamespace: "entry.relationship.${group.resourceId}",
      ),
    );
  }
}

class _EntryRoleHeader extends StatelessWidget {
  const _EntryRoleHeader({required this.id, required this.subjects});

  final EntryIdentifier id;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context) {
    final projection = switch (subjects) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (projection == null) {
      if (subjects?.hasError ?? subjects == null) {
        return presentationDiagnostic(context, const [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message: "Inspector header presentation is unavailable",
            pathPresent: false,
          ),
        ]);
      }
      return ShimmerBox.rectangle(width: double.infinity, height: 36);
    }
    final subject = projection.subjects[id.referenceId];
    final role = subject == null
        ? null
        : TypedAuthoringCodec(projection.catalog).subjectPresentation(
            subject,
            PresentationRole.inspectorHeader,
            collections: projection.collections,
          );
    final resolved = role?.valueOrNull;
    if (resolved == null) {
      return presentationDiagnostic(
        context,
        role?.diagnostics.isNotEmpty == true
            ? role!.diagnostics
            : projection.diagnostics.isNotEmpty
            ? projection.diagnostics
            : const [
                TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidPresentation,
                  message: "Inspector header presentation is unavailable",
                  pathPresent: false,
                ),
              ],
      );
    }
    return ComposedEditor(
      model: resolved.model,
      readOnly: true,
      historyNamespace: "entry.inspector.header.${id.id}",
    );
  }
}

/// Read only incoming and outgoing references grouped by related resource.
///
/// Resource activation opens the related resource. Usage activation preserves
/// the exact source slot and may request field focus when a typed source path
/// is available. Expansion and every activation use standard focusable
/// controls, so the list is fully keyboard operable.
class RelationshipList extends StatelessWidget {
  const RelationshipList({
    required this.relationships,
    required this.onOpenResource,
    required this.onOpenUsage,
    this.onFocusSourceField,
    this.groupBuilder,
    super.key,
  });

  final EntryRelationships relationships;
  final RelationshipResourceCallback onOpenResource;
  final RelationshipUsageCallback onOpenUsage;
  final RelationshipSourceFocusCallback? onFocusSourceField;
  final RelationshipGroupBuilder? groupBuilder;

  @override
  Widget build(BuildContext context) {
    if (relationships.incoming.isEmpty && relationships.outgoing.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (relationships.incoming.isNotEmpty)
          _RelationshipSection(
            label: "Incoming",
            icon: Icons.call_received,
            groups: relationships.incoming,
            onOpenResource: onOpenResource,
            onOpenUsage: onOpenUsage,
            onFocusSourceField: onFocusSourceField,
            groupBuilder: groupBuilder,
          ),
        if (relationships.outgoing.isNotEmpty)
          _RelationshipSection(
            label: "Outgoing",
            icon: Icons.call_made,
            groups: relationships.outgoing,
            onOpenResource: onOpenResource,
            onOpenUsage: onOpenUsage,
            onFocusSourceField: onFocusSourceField,
            groupBuilder: groupBuilder,
          ),
      ],
    );
  }
}

class _RelationshipSection extends StatelessWidget {
  const _RelationshipSection({
    required this.label,
    required this.icon,
    required this.groups,
    required this.onOpenResource,
    required this.onOpenUsage,
    required this.onFocusSourceField,
    required this.groupBuilder,
  });

  final String label;
  final IconData icon;
  final List<RelationshipGroup> groups;
  final RelationshipResourceCallback onOpenResource;
  final RelationshipUsageCallback onOpenUsage;
  final RelationshipSourceFocusCallback? onFocusSourceField;
  final RelationshipGroupBuilder? groupBuilder;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: EdgeInsets.zero,
    childrenPadding: EdgeInsets.zero,
    leading: Icon(icon, size: 18),
    title: Text(label),
    subtitle: Text("${groups.length} resources"),
    children: [
      for (final group in groups)
        _RelationshipGroupTile(
          group: group,
          onOpenResource: onOpenResource,
          onOpenUsage: onOpenUsage,
          onFocusSourceField: onFocusSourceField,
          groupBuilder: groupBuilder,
        ),
    ],
  );
}

class _RelationshipGroupTile extends StatelessWidget {
  const _RelationshipGroupTile({
    required this.group,
    required this.onOpenResource,
    required this.onOpenUsage,
    required this.onFocusSourceField,
    required this.groupBuilder,
  });

  final RelationshipGroup group;
  final RelationshipResourceCallback onOpenResource;
  final RelationshipUsageCallback onOpenUsage;
  final RelationshipSourceFocusCallback? onFocusSourceField;
  final RelationshipGroupBuilder? groupBuilder;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: ValueKey(group.resourceId),
    tilePadding: EdgeInsets.only(left: context.spacing.space2),
    childrenPadding: EdgeInsets.only(left: context.spacing.space4),
    title:
        groupBuilder?.call(context, group) ??
        Text(group.name, overflow: TextOverflow.ellipsis),
    subtitle: Text("${group.usages.length} usages"),
    trailing: IconButton(
      tooltip: "Open ${group.name}",
      onPressed: () => onOpenResource(group),
      icon: const Icon(Icons.open_in_new, size: 18),
    ),
    children: [
      for (final usage in group.usages)
        ListTile(
          key: ValueKey(usage.id),
          dense: true,
          title: Text(usage.slot, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.arrow_forward, size: 16),
          onTap: () async {
            await onOpenUsage(group, usage);
            final sourcePath = usage.sourcePath;
            if (sourcePath != null) {
              await onFocusSourceField?.call(usage.sourceId, sourcePath);
            }
          },
        ),
    ],
  );
}
