"""Regression guards for v30 source routing/UI contracts.
These checks do not compile Dart or test multi-device delivery.
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
R = Path(__file__).resolve().parents[1]
features = {
    'QR_OPENS_CHAT_AND_COMMUNITY': ('lib/screens/qr_screen.dart', ['ChatInboxRouter.directId(', 'ChatScreen(', 'CommunitiesScreen(joinCode:']),
    'QR_APPROVAL_COMMUNITY': ('lib/screens/communities_screen.dart', ["'join_request'", "'join_response'", 'sendPacket(packet)', 'QrImageView(']),
    'SAFE_RECIPIENT_BINDING': ('lib/screens/chat_screen.dart', ['_safeRecipientRoutes()', 'blousab_peer_id_', '_peerIdFromConversation()']),
    'PERSIST_FEED_MODE': ('lib/screens/public_feed_screen.dart', ['_feedModeKey', 'setBool(_feedModeKey']),
    'SINGLE_NOTIFICATION_ENTRY': ('lib/screens/public_feed_screen.dart', ['BlousabNotificationsScreen']),
    'SOCIAL_NOTIFICATIONS_CENTRAL': ('lib/services/social_signal_router.dart', ["'public_feed_update'", "'like', 'comment'", "'blousab_notifications_v1'"]),
    'CHAT_SHARED_POST': ('lib/screens/chat_screen.dart', ['_BlousabSharedPostPreview', 'sharedPostId']),
    'FILE_TRANSFER_CHUNK_SHA': ('lib/services/chat_inbox_router.dart', ["'file_chunk'", 'chunkSha256', "'file_done'", '64 * 1024', '32 * 1024']),
    'CHAT_CAMERA_EDITOR_AUDIO_VIDEO': ('lib/screens/chat_screen.dart', ['ImageSource.camera', 'openImageEditor(', 'openVideoEditor(', 'AudioRecorder()', 'VideoPlayerController.file', 'AudioPlayer()']),
    'FOLLOWER_FOLLOWING_SEPARATE': ('lib/services/follow_store.dart', ['followingKey', 'followersKey', 'follow_change', 'follow_ack']),
    'PROFILE_POST_VIDEO': ('lib/screens/user_profile_screen.dart', ['_ProfilePostVideo', '_openPost(', 'FollowListScreen(']),
    'CHAT_READ_ACK': ('lib/services/chat_inbox_router.dart', ['acknowledgeOpenConversation(', "'read_ack'", 'markRead(']),
    'CENTRAL_WIFI_AWARE_RECEIVER': ('lib/main.dart', ['_notificationAwareSubscription', "event.type == 'dataPacket'", '_notifyForIncoming(event.payload!']),
    'WIFI_AWARE_GROUP_JOIN': ('lib/screens/communities_screen.dart', ['_awareSubscription', '_handleLanEvent(BlousabEvent(']),
    'BACKGROUND_FOREGROUND_SERVICE': ('android/app/src/main/kotlin/com/plosap/myapp/BlousabConnectionService.kt', ['startForeground(', 'R.drawable.ic_stat_blousab', 'NOTIFICATION_ID']),
    'AI_PROGRESS_EXISTING': ('lib/services/blousab_ai_service.dart', ['_kDownloadId', '_kExpectedHash']),
}
fail = 0
for name, (file, patterns) in features.items():
    path = R / file
    if not path.exists():
        print('FAIL', name, 'missing file', file)
        fail += 1
        continue
    src = path.read_text()
    absent = [p for p in patterns if p not in src]
    if absent:
        print('FAIL', name, 'missing', absent)
        fail += 1
    else:
        print('PASS', name)
try:
    ET.parse(R/'android/app/src/main/AndroidManifest.xml')
    for folder in ('mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'):
        assert (R/f'android/app/src/main/res/drawable-{folder}/ic_stat_blousab.png').stat().st_size > 200
    print('PASS ANDROID_MANIFEST_NOTIFICATION_RESOURCES')
except (ET.ParseError, AssertionError, FileNotFoundError) as ex:
    fail += 1
    print('FAIL ANDROID_MANIFEST_NOTIFICATION_RESOURCES', str(ex))
print('NOTE: Source checks cannot prove Flutter compilation, transport background behavior, speed, QR delivery, or E2E security.')
sys.exit(1 if fail else 0)
