import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum AppSound {
  click('audio/sfx/click.wav', 0.45),
  countdownTick('audio/sfx/countdown_tick.wav', 0.5),
  countdownGo('audio/sfx/countdown_go.wav', 0.55),
  zoneSwoosh('audio/sfx/zone_swoosh.wav', 0.55),
  zonePulse('audio/sfx/zone_pulse.wav', 0.48),
  plaquePop('audio/sfx/plaque_pop.wav', 0.5),
  pause('audio/sfx/pause.wav', 0.42),
  resume('audio/sfx/resume.wav', 0.45),
  sessionComplete('audio/sfx/session_complete.wav', 0.58);

  const AppSound(this.assetPath, this.volume);

  final String assetPath;
  final double volume;
}

class AppAudioService {
  AppAudioService._();

  static final AppAudioService instance = AppAudioService._();

  final Map<AppSound, AudioPlayer> _players = {};

  void play(AppSound sound) {
    unawaited(_play(sound));
  }

  Future<void> _play(AppSound sound) async {
    try {
      final player = _players[sound] ??= await _createPlayer();
      await player.stop();
      await player.play(AssetSource(sound.assetPath), volume: sound.volume);
    } catch (_) {
      // Audio should never block brushing if an asset or platform player fails.
    }
  }

  Future<AudioPlayer> _createPlayer() async {
    final player = AudioPlayer();
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  Future<void> dispose() async {
    final players = _players.values.toList();
    _players.clear();
    for (final player in players) {
      await player.dispose();
    }
  }
}
