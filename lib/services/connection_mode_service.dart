import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The mode changes which outgoing path Blousab prefers. It must not stop
/// passive discovery/relay sessions or disconnect existing conversations.
/// Hardware support and Android Wi-Fi Aware coexistence are still required.
class ConnectionModeService {
  ConnectionModeService._();
  static final ConnectionModeService instance = ConnectionModeService._();
  static const String key = 'blousab_connection_mode';
  static const List<String> values = <String>['dual', 'bluetooth', 'wifi'];
  final ValueNotifier<String> mode = ValueNotifier<String>('dual');

  String get selected => mode.value;
  bool get preferWifi => selected != 'bluetooth';
  bool get allowBluetoothData => selected != 'wifi';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);
    mode.value = values.contains(saved) ? saved! : 'dual';
  }

  Future<void> set(String next) async {
    if (!values.contains(next)) throw ArgumentError.value(next, 'mode');
    mode.value = next;
    (await SharedPreferences.getInstance()).setString(key, next);
  }

  Future<void> cycle() => set(values[(values.indexOf(selected) + 1) % values.length]);
}
