import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android's LocalOnlyHotspot: clients can communicate on the local subnet,
/// but Android does NOT route internet through this hotspot. A phone must still
/// join using the system's Wi-Fi controls/approved APIs; apps cannot silently
/// force every peer to join. SoftAP may preclude Wi-Fi Aware on some hardware.
class BlousabLocalHotspotService {
  BlousabLocalHotspotService._();
  static final BlousabLocalHotspotService instance = BlousabLocalHotspotService._();
  static const MethodChannel _channel = MethodChannel('com.blousab.messenger/local_hotspot');
  final ValueNotifier<Map<String, String>?> state = ValueNotifier(null);
  Future<Map<String, String>?>? _starting;

  Future<Map<String, String>?> ensureStarted() => _starting ??= _start().whenComplete(() => _starting = null);

  Future<Map<String, String>?> _start() async {
    try {
      final result = await _channel.invokeMapMethod<String, String>('start');
      state.value = result;
      return result;
    } on PlatformException catch (e) {
      debugPrint('Local-only hotspot unavailable: ${e.code} ${e.message}');
      return null;
    } catch (_) { return null; }
  }

  Future<void> stop() async {
    try { await _channel.invokeMethod<bool>('stop'); } catch (_) {}
    state.value = null;
  }
}
