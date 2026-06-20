import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KdsAudioNotifier extends Notifier<bool> {
  final AudioPlayer _player = AudioPlayer();

  @override
  bool build() {
    return false; // isMuted = false
  }

  Future<void> playNewOrderSound() async {
    if (state) return; // Nếu đang Mute thì bỏ qua
    try {
      await _player.play(UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'), volume: 1.0);
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  void toggleMute() {
    state = !state;
  }
}

final kdsAudioProvider = NotifierProvider<KdsAudioNotifier, bool>(KdsAudioNotifier.new);
