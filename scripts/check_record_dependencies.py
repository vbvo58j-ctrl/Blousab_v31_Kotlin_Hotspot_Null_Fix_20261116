#!/usr/bin/env python3
"""Check compatible federated record plugin versions in pubspec and pubspec.lock.

Works offline. This guard is not a Dart compiler or a replacement for pub get.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSIONS = {
    "record": "6.2.1",
    "record_linux": "1.3.1",
    "record_platform_interface": "1.6.0",
}


def yaml_mapping_value(source: str, key: str, indent: int = 2):
    pattern = rf"^{' ' * indent}{re.escape(key)}:\s*[\"']?([^\s\"'#]+)"
    match = re.search(pattern, source, re.MULTILINE)
    return match.group(1) if match else None


def resolved_version(lock: str, package: str):
    # Each package block is a top-level child of `packages:` in pubspec.lock.
    match = re.search(
        rf"^  {re.escape(package)}:\s*\n(?P<block>(?:^    [^\n]*\n)*)",
        lock, re.MULTILINE,
    )
    if not match:
        return None
    return yaml_mapping_value(match.group('block'), 'version', indent=4)


def main():
    config = (ROOT / 'pubspec.yaml').read_text(encoding='utf8')
    errors = []
    for name, version in VERSIONS.items():
        got = yaml_mapping_value(config, name)
        if got != version:
            errors.append(f'pubspec.yaml {name}: expected exact {version}, got {got!r}')
    lock_path = ROOT / 'pubspec.lock'
    if lock_path.exists():
        lock = lock_path.read_text(encoding='utf8')
        for name, version in VERSIONS.items():
            got = resolved_version(lock, name)
            if got != version:
                errors.append(f'pubspec.lock {name}: expected {version}, got {got!r}')
    else:
        print('INFO: pubspec.lock not found: run flutter pub get in CI/device first.')
    for error in errors:
        print('FAIL:', error)
    if errors:
        print('ACTION: run flutter pub get after updating pubspec.yaml; do not edit .pub-cache.')
        return 1
    print('PASS: record 6.2.1 + record_linux 1.3.1 + record_platform_interface 1.6.0')
    print('NOTE: Flutter analyze and build must still run to verify compilation.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
