import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Multi-track ambient soundscape player supporting concurrent track volume mixing
/// (Rain, White Noise, Cafe, Library, Waves).
class AmbientSoundscapePlayer {
  static const List<String> supportedTracks = [
    'rain',
    'white_noise',
    'cafe',
    'library',
    'waves',
  ];

  final Map<String, AudioPlayer> _players = {};
  final Map<String, double> _volumes = {
    'rain': 0.0,
    'white_noise': 0.0,
    'cafe': 0.0,
    'library': 0.0,
    'waves': 0.0,
  };
  final Map<String, bool> _playing = {
    'rain': false,
    'white_noise': false,
    'cafe': false,
    'library': false,
    'waves': false,
  };

  AmbientSoundscapePlayer() {
    for (final track in supportedTracks) {
      _players[track] = AudioPlayer();
    }
  }

  static String normalizeTrackName(String track) {
    final lower = track.trim().toLowerCase().replaceAll(' ', '_');
    if (supportedTracks.contains(lower)) {
      return lower;
    }
    for (final s in supportedTracks) {
      if (lower.contains(s) || s.contains(lower)) {
        return s;
      }
    }
    return lower;
  }

  /// Sets volume for a specific track (0.0 to 1.0)
  Future<void> setTrackVolume(String track, double volume) async {
    final key = normalizeTrackName(track);
    final clamped = volume.clamp(0.0, 1.0);
    _volumes[key] = clamped;

    final player = _players[key];
    if (player != null) {
      try {
        await player.setVolume(clamped);
      } catch (_) {
        // Platform fallback for headless/test environments
      }
    }

    if (clamped == 0.0 && (_playing[key] ?? false)) {
      await stopTrack(key);
    } else if (clamped > 0.0 && !(_playing[key] ?? false)) {
      await playTrack(key, volume: clamped);
    }
  }

  /// Gets the current volume for a track
  double getTrackVolume(String track) {
    final key = normalizeTrackName(track);
    return _volumes[key] ?? 0.0;
  }

  /// Returns whether a track is currently active/playing
  bool isTrackPlaying(String track) {
    final key = normalizeTrackName(track);
    return _playing[key] ?? false;
  }

  /// Plays a track with optional volume (loops indefinitely)
  Future<void> playTrack(String track, {double? volume}) async {
    final key = normalizeTrackName(track);
    final targetVolume = (volume ?? _volumes[key] ?? 0.5).clamp(0.0, 1.0);
    _volumes[key] = targetVolume;
    _playing[key] = true;

    final player = _players[key];
    if (player != null) {
      try {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(targetVolume);
        await player.play(AssetSource('sounds/$key.mp3'));
      } catch (_) {
        // Graceful fallback for non-mobile/headless environments
      }
    }
  }

  /// Stops a track
  Future<void> stopTrack(String track) async {
    final key = normalizeTrackName(track);
    _playing[key] = false;

    final player = _players[key];
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {
        // Graceful fallback
      }
    }
  }

  /// Stops all playing soundscape tracks
  Future<void> stopAll() async {
    for (final track in supportedTracks) {
      await stopTrack(track);
    }
  }

  /// Read-only snapshot of all track volumes
  Map<String, double> get allTrackVolumes => Map.unmodifiable(_volumes);

  /// Read-only snapshot of all track playing states
  Map<String, bool> get allPlayingStates => Map.unmodifiable(_playing);

  /// Disposes all audio player instances
  Future<void> dispose() async {
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}
