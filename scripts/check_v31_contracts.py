#!/usr/bin/env python3
"""v31 static source guards only; DOES NOT certify Flutter compilation or devices."""
from pathlib import Path
import sys, yaml, xml.etree.ElementTree as ET
base = Path(__file__).resolve().parents[1]
get = lambda p: (base/p).read_text(encoding='utf-8')
main = get('lib/main.dart')
chat = get('lib/screens/chat_screen.dart')
router = get('lib/services/chat_inbox_router.dart')
notif = get('lib/services/notification_service.dart')
stories = get('lib/screens/stories_strip.dart')
feed = get('lib/screens/public_feed_screen.dart')
top = get('lib/widgets/blousab_visuals.dart')
mode = get('lib/services/connection_mode_service.dart')
hotspot = get('android/app/src/main/kotlin/com/plosap/myapp/MainActivity.kt')
settings = get('lib/screens/settings_pages.dart')
gallery = get('lib/screens/blousab_device_gallery.dart')
report = {
  'CONNECTION_MODE_DUAL_DEFAULT': "ValueNotifier<String>('dual')" in mode and "'dual', 'bluetooth', 'wifi'" in mode,
  'CONNECTION_MODE_SAVED': "SharedPreferences.getInstance()" in mode and 'ConnectionModeService.instance.load()' in main,
  'QUICK_MODE_TOGGLE': 'BlousabConnectionModeButton' in top and 'ConnectionModeService.instance.cycle()' in top,
  'WIFI_AWARE_AND_LOCAL_ONLY_HOTSPOT': 'WifiAwareService.instance.start' in main and 'BlousabLocalHotspotService.instance.ensureStarted()' in main and 'startLocalOnlyHotspot' in hotspot,
  'HOTSPOT_NO_TETHERING': 'LocalOnlyHotspotCallback' in hotspot and 'startTethering' not in hotspot,
  'GALLERY_TWO_TABS': "RequestType.image" in gallery and 'RequestType.video' in gallery and "'الصور'" in gallery and "'الفيديوهات'" in gallery,
  'ATTACHMENT_MENU': all(x in chat for x in ["'contact'", "'document'", "'file'", "'apk'", "'gallery'"]),
  'MEDIA_BUBBLE_PROGRESS': '_transferProgress.containsKey(message.id)' in chat and '_cancelTransfers.add(message.id)' in chat and 'child: Column(mainAxisSize: MainAxisSize.min, children: [\n      content,' in chat,
  'PHOTO_VIDEO_INLINE': '_BlousabInlineVideo' in chat and 'Image.file(' in chat,
  'RECEIPTS_ACK_REQUIRED': 'await completer.future.timeout' in chat and 'A successful socket write alone must never turn ticks into two' in chat,
  'LONG_TEXT_SHA256': "'textEncoding': 'gzip-base64'" in chat and "'textSha256': sha256.convert(textBytes).toString()" in chat and "'textEncoding'" in router and 'gzip.decode' in router,
  'READ_MORE': '_BlousabExpandableText' in chat and 'قراءة المزيد' in chat,
  'CHAT_SOUNDS': 'ChatSoundService.instance.incoming()' in chat and 'ChatSoundService.instance.outgoing()' in chat and all((base/f'assets/sounds/{n}').exists() for n in ('message_received.wav','message_sent.wav')),
  'PRIVACY': all(x in settings for x in ('blousab_hide_notification_text','blousab_hide_online','blousab_hide_last_seen','blousab_ghost_no_discovery')),
  'FILE_INTEGRITY': 'sha256.bind(file.openRead())' in router and 'chunkSha256' in router and '_decodeBounded' in router,
  'FOLLOW_ACCEPTANCE_NOTIFICATION': "'follow_accepted'" in feed and "'follow_accepted'" in get('lib/screens/blousab_notifications_screen.dart') and "'follow_accepted'" in notif,
  'STORIES_USE_CURRENT_NAME': '_storyDisplayName' in stories and 'BlousabPresence.instance.profileOf(ownerId)' in stories,
  'PRESENCE_OFFLINE_DOT': 'showStatusDot: true' in chat and 'Color(0xFFE8404D)' in top,
}
try:
  pub = yaml.safe_load(get('pubspec.yaml'))
  report['FLUTTER_DEPS_AND_AUDIO_ASSETS'] = 'photo_manager' in pub['dependencies'] and 'flutter_contacts' in pub['dependencies'] and all('assets/sounds/'+n in pub['flutter']['assets'] for n in ('message_received.wav', 'message_sent.wav'))
  ET.parse(base/'android/app/src/main/AndroidManifest.xml')
  report['ANDROID_MANIFEST_XML'] = True
except Exception as e:
  report['FLUTTER_DEPS_AND_AUDIO_ASSETS'] = False
  report['ANDROID_MANIFEST_XML'] = False
  print('ERROR parsing resources:',e)
for label, passed in report.items():
  print(('PASS' if passed else 'FAIL') + ': ' + label)
print('STATIC_CONTRACTS_PASS=%d FAIL=%d' % (sum(report.values()), len(report) - sum(report.values())))
print('NOTE: These are source-presence checks, not runtime, Wi-Fi, Bluetooth, Android, or E2E-security tests.')
sys.exit(1 if not all(report.values()) else 0)
