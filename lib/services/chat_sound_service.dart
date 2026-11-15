import 'package:audioplayers/audioplayers.dart';

/// Quiet, original in-app chat tones. Independent player instances avoid
/// cutting off the incoming chime when another chat sends concurrently.
class ChatSoundService {
  ChatSoundService._();
  static final ChatSoundService instance = ChatSoundService._();
  final AudioPlayer _receive = AudioPlayer();
  final AudioPlayer _send = AudioPlayer();

  Future<void> incoming() async {
    try { await _receive.play(AssetSource('sounds/message_received.wav'), volume: 0.45); }
    catch (_) { /* A sound error must never block reading a message. */ }
  }

  Future<void> outgoing() async {
    try { await _send.play(AssetSource('sounds/message_sent.wav'), volume: 0.4); }
    catch (_) { /* Never interfere with message storage/transmission. */ }
  }
}
