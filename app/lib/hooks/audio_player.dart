import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

AudioPlayer useAudioPlayer({
  double volume = 1.0,
}) {
  return use(_AudioPlayerHook(volume: volume));
}

class _AudioPlayerHook extends Hook<AudioPlayer> {
  const _AudioPlayerHook({required this.volume});
  final double volume;
  @override
  _AudioPlayerHookState createState() => _AudioPlayerHookState();
}

class _AudioPlayerHookState extends HookState<AudioPlayer, _AudioPlayerHook> {
  late AudioPlayer player;
  @override
  void initHook() {
    super.initHook();
    player = AudioPlayer();
    player.setVolume(hook.volume);
  }

  @override
  AudioPlayer build(BuildContext context) {
    return player;
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
