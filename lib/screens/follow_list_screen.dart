import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/follow_store.dart';
import '../services/presence_service.dart';
import '../widgets/blousab_page.dart';
import 'user_profile_screen.dart';

/// Lists the user's own followers / followed accounts; no proxy friend counts.
class FollowListScreen extends StatefulWidget {
  const FollowListScreen({super.key, required this.followers, this.ownerId});
  final String? ownerId;
  final bool followers;
  @override State<FollowListScreen> createState() => _FollowListScreenState();
}
class _FollowListScreenState extends State<FollowListScreen> {
  List<String> _ids = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final me = prefs.getString('wasl_user_id') ?? '';
    if (widget.ownerId != null && widget.ownerId!.isNotEmpty && widget.ownerId != me) {
      final profile = BlousabPresence.instance.profileOf(widget.ownerId!);
      if (mounted) setState(() => _ids = widget.followers
          ? (profile?.followerIds ?? <String>[]) : (profile?.followingIds ?? <String>[]));
    } else {
      final key = widget.followers ? FollowStore.followersKey : FollowStore.followingKey;
      if (mounted) setState(() => _ids = prefs.getStringList(key) ?? <String>[]);
    }
  }
  @override Widget build(BuildContext context) => BlousabPage(
    title: widget.followers ? 'المتابعون' : 'المتابَعون',
    child: _ids.isEmpty ? const Center(child: Text('لا توجد حسابات متاحة في هذه القائمة بعد، أو لم تتم مزامنتها.'))
        : ListView.builder(itemCount: _ids.length, itemBuilder: (context, i) {
          final id = _ids[i];
          final name = BlousabPresence.instance.nameOf(id);
          return ListTile(leading: CircleAvatar(child: const Icon(Icons.person_outline)),
            title: Text(name), subtitle: Text(id, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_left), onTap: () async {
              await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => UserProfileScreen(userId: id, fallbackName: name)));
              await _load();
            });
        }),
  );
}
