#!/usr/bin/env python3
"""Regression guard for nullable Android LocalOnlyHotspot WifiConfiguration."""
from pathlib import Path

source = (Path(__file__).resolve().parents[1] / 'android/app/src/main/kotlin/com/plosap/myapp/MainActivity.kt').read_text(encoding='utf-8')
start = source.index('private fun startLocalOnlyHotspot(')
end = source.index('private fun startWifiAware(', start)
section = source[start:end]
checks = {
    'legacy nullable configuration checked before member access':
        'val legacy = reservation.wifiConfiguration' in section and
        'if (legacy == null)' in section and
        section.index('if (legacy == null)') < section.index('legacy.SSID') and
        section.index('if (legacy == null)') < section.index('legacy.preSharedKey'),
    'graceful error returned when Android supplies no credentials':
        'LOCAL_HOTSPOT_CONFIGURATION' in section and 'result.error(' in section,
    'reservation closed when configuration is missing':
        'try { reservation.close() }' in section,
    'legacy SSID and password retained on supported Android devices':
        'ssid = legacy.SSID?.trim' in section and 'password = legacy.preSharedKey?.trim' in section,
    'newer Android SoftApConfiguration path maintained':
        'reservation.softApConfiguration.ssid' in section and
        'reservation.softApConfiguration.passphrase' in section,
}
for label, passed in checks.items():
    print(('PASS' if passed else 'FAIL') + ': ' + label)
if not all(checks.values()):
    raise SystemExit(1)
