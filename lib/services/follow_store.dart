import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'presence_service.dart';

/// Separate followers/following identities; unlike mutual QR friendships.
/// Pending changes are retained for retries while app engine runs.
class FollowStore {
  FollowStore._();
  static final FollowStore instance = FollowStore._();
  static const followingKey = 'blousab_following_v1';
  static const followersKey = 'blousab_followers_v1';
  static const _outboxKey = 'blousab_follow_outbox_v1';
  static Future<void> _chain = Future<void>.value();

  Future<List<String>> following() async =>
      (await SharedPreferences.getInstance()).getStringList(followingKey) ?? <String>[];
  Future<List<String>> followers() async =>
      (await SharedPreferences.getInstance()).getStringList(followersKey) ?? <String>[];

  Future<bool> toggle(String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getString('wasl_user_id') ?? '';
    if (myId.isEmpty || targetId.isEmpty || targetId == myId) return false;
    final list = (prefs.getStringList(followingKey) ?? <String>[]).toSet();
    final isFollowing = !list.contains(targetId);
    if (isFollowing) { list.add(targetId); } else { list.remove(targetId); }
    await prefs.setStringList(followingKey, list.toList());
    final now = DateTime.now().millisecondsSinceEpoch;
    final packet = jsonEncode({
      'type': 'follow_change', 'senderId': myId, 'senderName': prefs.getString('wasl_user_name') ?? 'مستخدم بلوساب',
      'recipientId': targetId, 'following': isFollowing, 'at': now,
      'requestId': '${myId}_${targetId}_$now',
    });
    final outbox = prefs.getStringList(_outboxKey) ?? <String>[];
    outbox.removeWhere((row) { try { return jsonDecode(row)['recipientId'] == targetId; } catch (_) { return false; } });
    outbox.add(packet);
    await prefs.setStringList(_outboxKey, outbox);
    await BlousabPresence.instance.sendPacket(packet);
    return isFollowing;
  }

  Future<void> retry() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = prefs.getStringList(_outboxKey) ?? <String>[];
    for (final packet in messages.take(30)) { await BlousabPresence.instance.sendPacket(packet); }
  }

  Future<void> accept(String raw, String myId) async {
    if (myId.isEmpty || raw.length > 8192) return;
    Map<String, dynamic> packet;
    try { final value = jsonDecode(raw); if (value is! Map) return; packet = Map<String, dynamic>.from(value); }
    catch (_) { return; }
    if (packet['recipientId']?.toString() != myId) return;
    final kind = packet['type']?.toString() ?? '';
    if (kind == 'follow_ack') {
      final id = packet['requestId']?.toString() ?? '';
      if (id.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_outboxKey) ?? <String>[];
      queue.removeWhere((row) { try { return jsonDecode(row)['requestId'] == id; } catch (_) { return false; } });
      await prefs.setStringList(_outboxKey, queue);
      return;
    }
    if (kind != 'follow_change') return;
    final sender = packet['senderId']?.toString() ?? '';
    final id = packet['requestId']?.toString() ?? '';
    final at = (packet['at'] as num?)?.toInt() ?? 0;
    if (sender.isEmpty || sender == myId || sender.length > 256 || at <= 0 || id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getInt('blousab_follow_at_$sender') ?? 0;
    if (at >= previous) {
      final followers = (prefs.getStringList(followersKey) ?? <String>[]).toSet();
      if (packet['following'] == true) { followers.add(sender); } else { followers.remove(sender); }
      await prefs.setStringList(followersKey, followers.toList());
      await prefs.setInt('blousab_follow_at_$sender', at);
    }
    await BlousabPresence.instance.sendPacket(jsonEncode({
      'type': 'follow_ack', 'recipientId': sender, 'senderId': myId, 'requestId': id,
    }));
  }
}
