import 'package:audioplayers/audioplayers.dart';

/// Plays the pre-recorded voice clips. Design rules (from the plan):
///  - Every screen auto-plays its prompt once, and has a big speaker button
///    that replays it — users who cannot read never need the text.
///  - Sequences play clip after clip with a short pause, so composed speech
///    (numbers, amounts) sounds like one sentence.
///  - If a clip file is missing the service stays silent instead of crashing;
///    placeholder clips ship in the bundle until the real recordings land.
class VoiceService {
  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;
  String lang = 'ps';
  int _runId = 0; // increments to cancel a sequence mid-play

  Future<void> _playOne(String key) async {
    try {
      await _player.play(AssetSource('audio/$lang/$key.mp3'));
      await _player.onPlayerComplete.first.timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );
    } catch (_) {
      // Missing/placeholder clip: keep the flow moving.
    }
  }

  Future<void> speak(String promptKey) async {
    if (!enabled) return;
    final run = ++_runId;
    await _player.stop();
    if (run != _runId) return;
    await _playOne(promptKey);
  }

  Future<void> speakSequence(List<String> clipKeys) async {
    if (!enabled) return;
    final run = ++_runId;
    await _player.stop();
    for (final key in clipKeys) {
      if (run != _runId) return; // a newer speak() took over
      await _playOne(key);
      if (run != _runId) return;
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  Future<void> stop() async {
    _runId++;
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
