import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

enum TopologyRepresentation { graph, list }

class TopologyView extends ConsumerStatefulWidget {
  const TopologyView({required this.topology, super.key});

  final OrganizationTopology topology;

  @override
  ConsumerState<TopologyView> createState() => _TopologyViewState();
}

class _TopologyViewState extends ConsumerState<TopologyView> {
  TopologyRepresentation _representation = TopologyRepresentation.graph;
  skir.RecordId? _selectedHostId;

  skir.ServiceHost? get _selectedHost {
    for (final host in widget.topology.hosts) {
      if (host.hostId == _selectedHostId) return host;
    }
    return null;
  }

  void _select(skir.RecordId id) => setState(() => _selectedHostId = id);

  @override
  Widget build(BuildContext context) {
    final selectedHost = _selectedHost;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final representation = narrow
            ? TopologyRepresentation.list
            : _representation;
        final topologySurface = Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.space4,
                context.spacing.space3,
                context.spacing.space4,
                context.spacing.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Runtime topology",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          "Ownership uses blue links. Engine assignment uses amber links.",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!narrow)
                    SegmentedButton<TopologyRepresentation>(
                      segments: const [
                        ButtonSegment(
                          value: TopologyRepresentation.graph,
                          icon: Icon(Icons.account_tree_outlined),
                          label: Text("Graph"),
                        ),
                        ButtonSegment(
                          value: TopologyRepresentation.list,
                          icon: Icon(Icons.view_list_outlined),
                          label: Text("List"),
                        ),
                      ],
                      selected: {_representation},
                      onSelectionChanged: (selection) =>
                          setState(() => _representation = selection.single),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: representation == TopologyRepresentation.graph
                    ? TopologyGraph(
                        key: const ValueKey("topology-graph"),
                        topology: widget.topology,
                        selectedHostId: _selectedHostId,
                        onHostSelected: _select,
                      )
                    : _TopologyList(
                        key: const ValueKey("topology-list"),
                        topology: widget.topology,
                        selectedHostId: _selectedHostId,
                        onHostSelected: _select,
                      ),
              ),
            ),
          ],
        );
        final inspector = selectedHost == null
            ? const _InspectorPlaceholder()
            : HostExecutionInspector(
                host: selectedHost,
                topology: widget.topology,
                onSave: (execution) => ref
                    .read(organizationTopologyStreamProvider.notifier)
                    .configureHost(host: selectedHost, execution: execution),
              );
        if (narrow) {
          return Column(
            children: [
              SizedBox(
                height: mathMin(constraints.maxHeight * 0.58, 520),
                child: topologySurface,
              ),
              const Divider(height: 1),
              Expanded(child: inspector),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: topologySurface),
            const VerticalDivider(width: 1),
            SizedBox(width: 370, child: inspector),
          ],
        );
      },
    );
  }
}

class _TopologyList extends StatelessWidget {
  const _TopologyList({
    required this.topology,
    required this.selectedHostId,
    required this.onHostSelected,
    super.key,
  });

  final OrganizationTopology topology;
  final skir.RecordId? selectedHostId;
  final ValueChanged<skir.RecordId> onHostSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(context.spacing.space3),
      itemCount: topology.hosts.length,
      separatorBuilder: (_, _) => SizedBox(height: context.spacing.space2),
      itemBuilder: (context, index) {
        final host = topology.hosts[index];
        final realm = topology.realmOwnedBy(host.hostId);
        final engine = topology.engineOwnedBy(host.hostId);
        return Material(
          color: host.hostId == selectedHostId
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: context.shapes.mediumBorderRadius,
          child: ListTile(
            selected: host.hostId == selectedHostId,
            onTap: () => onHostSelected(host.hostId),
            leading: Icon(
              host.entrypoint == skir.HostEntrypoint.paper
                  ? Icons.sports_esports_outlined
                  : Icons.cloud_outlined,
            ),
            title: Text(
              host.entrypoint == skir.HostEntrypoint.paper
                  ? "Paper host"
                  : "Standalone host",
            ),
            subtitle: Text(
              [
                host.hostId.id,
                if (realm != null)
                  "Realm ${realm.targetEngine.engineId} ${realm.targetEngine.majorVersion}.x",
                if (engine != null)
                  "${engine.target.engineId.formatted} engine on ${engine.realmId.id}",
              ].join("  ·  "),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _InspectorPlaceholder extends StatelessWidget {
  const _InspectorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing.space3),
            Text(
              "Select a host",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              "Choose a host in the graph or list to configure its execution.",
            ),
          ],
        ),
      ),
    );
  }
}

double mathMin(double first, double second) => first < second ? first : second;
