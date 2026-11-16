import "package:typewriter_panel/typewriter_panel.dart";

/// A service in the primary search: its name over the state its card on the
/// services page shows, in the same status colour.
class ServiceSearchResultItem extends StatelessWidget {
  const ServiceSearchResultItem({
    required this.item,
    required this.row,
    super.key,
  });

  final ServiceSearchItem item;
  final SearchResultRowContext row;

  @override
  Widget build(BuildContext context) {
    final ServiceSearchItem(:service, :host, :connected) = item;
    final (status, tone) = switch (host) {
      _ when !connected => ("Offline", TopologyStatusTone.offline),
      final host? => (
        hostRuntimeStatusLabel(host.state.status),
        topologyHostStatusTone(host.state.status),
      ),
      null => ("Connected", TopologyStatusTone.active),
    };
    final icon = switch (host) {
      final host? when host.entrypoint == "PAPER" =>
        Icons.sports_esports_outlined,
      _? => Icons.cloud_outlined,
      null => service.icon,
    };
    return SearchResultRow(
      row: row,
      density: SearchResultDensity.card,
      title: service.displayName,
      accent: service.color,
      leading: Icon(icon),
      kindLabel: "service",
      body: TopologyStatusIndicator(
        label: status,
        tone: tone,
        color: service.color,
      ),
    );
  }
}
