part of "scene.dart";

class _GeneratedEntry {
  const _GeneratedEntry({
    required this.id,
    required this.name,
    required this.icon,
    required this.placement,
    required this.data,
    required this.children,
  });

  final String id;
  final String name;
  final String icon;
  final EntryPlacement placement;
  final RecordValue data;
  final List<SceneCueDsl> children;
}

class _SceneCueKind {
  const _SceneCueKind({
    required this.name,
    required this.icon,
    required this.channel,
  });

  final String name;
  final String icon;
  final String channel;
}

ElementDefinition generateSceneElementDefinition({
  required String id,
  required String name,
  required String icon,
}) {
  return ElementDefinition(
    rootType: ResolvedTypeRef(
      id: fixtureDeclaredTypeId("scene:$id"),
      revision: 1,
    ),
    name: name,
    description: "$name for scene stories",
    color: safeColors[id.hashCode.abs() % safeColors.length],
    icon: IconValue.iconify(icon),
  );
}

const _rootCueKinds = [
  _SceneCueKind(
    name: "Entity Segment",
    icon: "fa7-solid:user",
    channel: "entity",
  ),
  _SceneCueKind(name: "Title Segment", icon: "fa-solid:font", channel: "title"),
  _SceneCueKind(
    name: "Camera Segment",
    icon: "fa-solid:video",
    channel: "camera",
  ),
];

const _childCueKinds = [
  _SceneCueKind(
    name: "Motion Segment",
    icon: "fa7-solid:person-running",
    channel: "motion",
  ),
  _SceneCueKind(
    name: "Effect Segment",
    icon: "fa7-solid:burst",
    channel: "effect",
  ),
  _SceneCueKind(
    name: "Dialogue Segment",
    icon: "fa7-solid:comment",
    channel: "dialogue",
  ),
];

const _grandchildCueKinds = [
  _SceneCueKind(
    name: "Detail Segment",
    icon: "fa7-solid:wand-magic",
    channel: "detail",
  ),
  _SceneCueKind(
    name: "Signal Segment",
    icon: "fa7-solid:wave-square",
    channel: "signal",
  ),
  _SceneCueKind(
    name: "Accent Segment",
    icon: "fa7-solid:bolt",
    channel: "accent",
  ),
];
