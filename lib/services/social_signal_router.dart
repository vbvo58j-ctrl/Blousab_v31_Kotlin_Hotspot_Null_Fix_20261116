import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'presence_service.dart';

/// Receives post reactions in the app shell even when the feed screen is closed.
/// Only posts already locally known to belong to this user generate alerts.
class SocialSignalRouter {
  SocialSignalRouter._();
  static final SocialSignalRouter instance = SocialSignalRouter._();
  Future<void> accept(String raw, String myId) async {
    if (myId.isEmpty || raw.length > 1024 * 1024) return;
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      data = Map<String, dynamic>.from(decoded);
    } catch (_) { return; }
    if (data['type'] != 'public_feed_update') return;
    final actor = data['actorId']?.toString() ?? '';
    final action = data['action']?.toString() ?? '';
    final postId = data['postId']?.toString() ?? '';
    if (actor.isEmpty || actor == myId || postId.isEmpty || !const {'like', 'comment'}.contains(action)) return;
    final prefs = await SharedPreferences.getInstance();
    // Do not trust a claimed authorId alone: verify the post exists in this
    // device's saved feed and that its creator is the current account.
    var mine = false;
    for (final rawPost in prefs.getStringList('blousab_public_feed_v1') ?? <String>[]) {
      try {
        final post = jsonDecode(rawPost);
        if (post is Map && post['id'] == postId && post['authorId'] == myId) { mine = true; break; }
      } catch (_) {}
    }
    if (!mine) return;
    final updated = (data['updatedAt'] as num?)?.toInt() ?? 0;
    final id = '${postId}_${updated}_${actor}_$action';
    final notifications = prefs.getStringList('blousab_notifications_v1') ?? <String>[];
    if (notifications.any((row) { try { return jsonDecode(row)['id'] == id; } catch (_) { return false; } })) return;
    notifications.insert(0, jsonEncode({'id': id, 'type': action, 'senderId': actor,
      'sender': data['actorName']?.toString() ?? 'مستخدم بلوساب', 'postId': postId,
      'at': DateTime.now().toIso8601String()}));
    await prefs.setStringList('blousab_notifications_v1', notifications.take(200).toList());
    await BlousabBadges.refresh();
  }
}
