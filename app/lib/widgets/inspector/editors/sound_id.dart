import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fuzzy/fuzzy.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/sound.dart";
import "package:typewriter/models/sounds.dart";
import "package:typewriter/utils/audio_player.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/focused_notifier.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "sound_id.g.dart";

@riverpod
Fuzzy<MinecraftSound> _fuzzyMinecraftSounds(Ref ref) {
  final provider = ref.watch(minecraftSoundsProvider);
  final sounds = provider.map(
    data: (data) => data.value.entries.toList(),
    error: (_) => <MinecraftSound>[],
    loading: (_) => <MinecraftSound>[],
  );

  return Fuzzy(
    sounds,
    options: FuzzyOptions(
      threshold: 0.2,
      keys: [
        WeightedKey(
          name: "name",
          getter: (entry) =>
              entry.key.replaceAll(".", " ").replaceAll("_", " "),
          weight: 0.7,
        ),
        WeightedKey(
          name: "rawName",
          getter: (entry) => entry.key,
          weight: 0.7,
        ),
      ],
    ),
  );
}

class MinecraftSoundIdsFetcher extends SearchFetcher {
  const MinecraftSoundIdsFetcher({
    this.onSelect,
    this.disabled = false,
  });

  final FutureOr<bool?> Function(MinecraftSound)? onSelect;

  @override
  final bool disabled;

  @override
  String get title => "Sounds";

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final fuzzy = ref.read(_fuzzyMinecraftSoundsProvider);

    final results = fuzzy.search(query);

    return results
        .map(
          (result) => MinecraftSoundIdSearchElement(
            sound: result.item,
            onSelect: onSelect,
          ),
        )
        .toList();
  }

  @override
  MinecraftSoundIdsFetcher copyWith({
    bool? disabled,
  }) {
    return MinecraftSoundIdsFetcher(
      onSelect: onSelect,
      disabled: disabled ?? this.disabled,
    );
  }
}

class MinecraftSoundIdSearchElement extends SearchElement {
  const MinecraftSoundIdSearchElement({
    required this.sound,
    required this.onSelect,
  });

  final MinecraftSound sound;
  final FutureOr<bool?> Function(MinecraftSound)? onSelect;

  @override
  String get title => sound.name.formatted;

  @override
  Color color(BuildContext context) {
    switch (sound.category) {
      case "block":
        return Colors.blue;
      case "entity":
        return Colors.red;
      case "item":
        return Colors.green;
      case "music":
        return Colors.orange;
      case "music_disc":
        return Colors.orange;
      case "ui":
        return Colors.yellow;
      case "weather":
        return Colors.teal;
      case "ambient":
        return Colors.cyan;
      case "enchant":
        return Colors.purple;
      case "particle":
        return Colors.pink;
      case "event":
        return Colors.indigoAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget icon(BuildContext context) => _FocusedAudioPlayer(sound: sound);

  @override
  Widget suffixIcon(BuildContext context) =>
      const Iconify(TWIcons.externalLink);

  @override
  String description(BuildContext context) {
    if (sound.value.length > 1) {
      return "${sound.category.formatted} (${sound.value.length} Sound ${sound.value.length.pluralize("track")})";
    } else {
      return sound.category.formatted;
    }
  }

  @override
  List<SearchAction> actions(PassingRef ref) {
    return [
      const SearchAction(
        "Select",
        TWIcons.check,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    return await onSelect?.call(sound) ?? true;
  }
}

class _FocusedAudioPlayer extends HookConsumerWidget {
  const _FocusedAudioPlayer({
    required this.sound,
  });

  final MinecraftSound sound;

  void _playSound(PassingRef ref) {
    if (!kIsWeb) return;
    final audioPlayer = ref.read(audioPlayerProvider);
    final url = sound.value.pickRandomSoundUrl();
    if (url == null) return;
    final source = UrlSource(url);
    audioPlayer.play(source);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(duration: 1.seconds);
    final hovering = useState(false);
    final hasFocus = FocusedNotifier.isFocused(context);
    final audioPlayer = ref.watch(audioPlayerProvider);

    final showPlaying = hasFocus || hovering.value;

    useEffect(
      () {
        if (showPlaying) {
          _playSound(ref.passing);
          controller.forward(from: 0);
        } else if (!showPlaying) {
          audioPlayer.stop();
          controller.reset();
        }
        return null;
      },
      [hasFocus, hovering.value],
    );

    return AspectRatio(
      aspectRatio: 1 / 2,
      child: MouseRegion(
        onEnter: (_) => hovering.value = true,
        onExit: (_) => hovering.value = false,
        child: Iconify(
          showPlaying ? TWIcons.volumeHigh : TWIcons.play,
          size: 16,
        )
            .animate(controller: controller, autoPlay: false)
            .scaleXY(duration: 300.ms, begin: 1, end: 1.2)
            .shake(
              delay: 100.ms,
              duration: 500.ms,
              curve: Curves.easeInOutCubicEmphasized,
            )
            .scaleXY(delay: 600.ms, duration: 300.ms, begin: 1.2, end: 1),
      ),
    );
  }
}

extension _SearchBuilderX on SearchBuilder {
  void fetchMinecraftSoundIds({
    FutureOr<bool?> Function(MinecraftSound)? onSelect,
    bool disabled = false,
  }) {
    fetch(MinecraftSoundIdsFetcher(onSelect: onSelect, disabled: disabled));
  }
}

class SoundIdEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "soundId";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => SoundSelectorEditor(
        path: path,
        customBlueprint: dataBlueprint as CustomBlueprint,
      );
}

class SoundSelectorEditor extends HookConsumerWidget {
  const SoundSelectorEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  bool? _update(PassingRef ref, SoundId soundId) {
    ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref, path, soundId.toJson());
    return null;
  }

  void _select(PassingRef ref) {
    ref.read(searchProvider.notifier).asBuilder()
      ..tag("sound_id", canRemove: false)
      ..nonGenericAddEntry()
      ..fetchEntry(
        onSelect: (entry) => _update(ref, SoundId.entry(entryId: entry.id)),
      )
      ..fetchMinecraftSoundIds(
        onSelect: (sound) => _update(ref, SoundId(id: sound.key)),
      )
      ..fetchNewEntry(
        onAdded: (entry) => _update(ref, SoundId.entry(entryId: entry.id)),
      )
      ..open();
  }

  void _unselect(PassingRef ref) {
    ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref, path, customBlueprint.defaultValue());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(fieldValueProvider(path, customBlueprint.defaultValue()));
    final soundId =
        data != null ? SoundId.fromJson(data) : const SoundId(id: "");

    return soundId.map(
      (soundId) => _DefaultSoundIdSelector(
        soundId: soundId,
        select: () => _select(ref.passing),
        unselect: () => _unselect(ref.passing),
      ),
      entry: (soundId) => _EntrySoundIdSelector(
        soundId: soundId,
        select: () => _select(ref.passing),
        unselect: () => _unselect(ref.passing),
      ),
    );
  }
}

class _DefaultSoundIdSelector extends HookConsumerWidget {
  const _DefaultSoundIdSelector({
    required this.soundId,
    required this.select,
    required this.unselect,
  });

  final DefaultSoundId soundId;
  final VoidCallback select;
  final VoidCallback unselect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound = ref.watch(minecraftSoundProvider(soundId.id));

    return sound.map(
      data: (data) {
        final value = data.value;
        if (value == null) return _EmptySelector(select: select);
        return _MinecraftSelector(
          sound: value,
          select: select,
          unselect: unselect,
        );
      },
      loading: (_) => const _LoadingSelector(),
      error: (error) {
        debugPrint(error.error.toString());
        debugPrintStack(
          label: "SoundSelectorEditor",
          maxFrames: 10,
          stackTrace: error.stackTrace,
        );
        return _ErrorSelector(select: select, unselect: unselect);
      },
    );
  }
}

class _EntrySoundIdSelector extends HookConsumerWidget {
  const _EntrySoundIdSelector({
    required this.soundId,
    required this.select,
    required this.unselect,
  });

  final EntrySoundId soundId;
  final VoidCallback select;
  final VoidCallback unselect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Selector(
      select: select,
      unselect: unselect,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
        child: Row(
          children: [
            Expanded(child: FakeEntryNode(entryId: soundId.entryId)),
            const SizedBox(width: 12),
            Iconify(
              TWIcons.caretDown,
              size: 16,
              color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _Selector extends HookConsumerWidget {
  const _Selector({
    required this.select,
    required this.child,
    required this.unselect,
  });

  final VoidCallback? select;
  final VoidCallback? unselect;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(8),
      child: ContextMenuRegion(
        builder: (context) => [
          if (select != null)
            ContextMenuTile.button(
              title: "Select Sound",
              icon: TWIcons.checkSquare,
              onTap: select,
            ),
          if (unselect != null)
            ContextMenuTile.button(
              title: "Remove Sound",
              icon: TWIcons.squareMinus,
              onTap: unselect,
              color: Colors.redAccent,
            ),
        ],
        child: InkWell(
          onTap: select,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EmptySelector extends HookConsumerWidget {
  const _EmptySelector({
    required this.select,
  });

  final VoidCallback select;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Selector(
      select: select,
      unselect: null,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note,
                    color:
                        Theme.of(context).inputDecorationTheme.hintStyle?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Select a sound",
                    style: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Iconify(
            TWIcons.caretDown,
            size: 16,
            color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
          ),
        ],
      ),
    );
  }
}

class _LoadingSelector extends HookConsumerWidget {
  const _LoadingSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Selector(
      select: null,
      unselect: null,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Loading Sounds...",
                style: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSelector extends HookConsumerWidget {
  const _ErrorSelector({
    required this.select,
    required this.unselect,
  });

  final VoidCallback select;
  final VoidCallback? unselect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Selector(
      select: select,
      unselect: unselect,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Failed to load sound",
                style: Theme.of(context)
                    .inputDecorationTheme
                    .hintStyle
                    ?.copyWith(color: Colors.redAccent),
              ),
            ),
            const SizedBox(width: 12),
            const Iconify(
              TWIcons.x,
              size: 16,
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _MinecraftSelector extends HookConsumerWidget {
  const _MinecraftSelector({
    required this.sound,
    required this.select,
    required this.unselect,
  });

  final MinecraftSound sound;
  final VoidCallback select;
  final VoidCallback unselect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Selector(
      select: select,
      unselect: unselect,
      child: Row(
        children: [
          Expanded(child: _ChosenSound(sound: sound)),
          const SizedBox(width: 12),
          Iconify(
            TWIcons.caretDown,
            size: 16,
            color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
          ),
        ],
      ),
    );
  }
}

class _ChosenSound extends HookConsumerWidget {
  const _ChosenSound({
    required this.sound,
  });

  final MinecraftSound sound;

  void _playSound(PassingRef ref) {
    if (!kIsWeb) return;
    final audioPlayer = ref.read(audioPlayerProvider);
    final url = sound.value.pickRandomSoundUrl();
    if (url == null) return;
    final source = UrlSource(url);
    audioPlayer.play(source);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(duration: 1.seconds);
    final hovering = useState(false);
    final audioPlayer = ref.watch(audioPlayerProvider);

    final showPlaying = hovering.value;

    useEffect(
      () {
        if (showPlaying) {
          _playSound(ref.passing);
          controller.forward(from: 0);
        } else {
          audioPlayer.stop();
          controller.reset();
        }
        return null;
      },
      [hovering.value],
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
      child: Row(
        children: [
          MouseRegion(
            onEnter: (_) => hovering.value = true,
            onExit: (_) => hovering.value = false,
            child: Iconify(
              showPlaying ? TWIcons.volumeHigh : TWIcons.play,
              size: 16,
            )
                .animate(controller: controller, autoPlay: false)
                .scaleXY(duration: 300.ms, begin: 1, end: 1.2)
                .shake(
                  delay: 100.ms,
                  duration: 500.ms,
                  curve: Curves.easeInOutCubicEmphasized,
                )
                .tint(color: Colors.amber)
                .scaleXY(delay: 600.ms, duration: 300.ms, begin: 1.2, end: 1),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sound.name.formatted,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                sound.category.formatted,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
