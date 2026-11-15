#!/usr/bin/env bash
# One-command acceptance test. Never deletes existing app data or .env files.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 2
pass=0; fail=0; skip=0
run_step() {
    local label="$1"; shift
    printf '\n===== %s =====\n' "$label"
    if "$@"; then echo "PASS: $label"; pass=$((pass + 1)); else echo "FAIL: $label"; fail=$((fail + 1)); fi
}
run_step "RECORD_DEPENDENCY_COMPAT" python3 scripts/check_record_dependencies.py
run_step "STATIC_SOURCE_AND_RESOURCES" python3 scripts/check_static.py
run_step "V26_SOURCE_CONTRACTS" python3 scripts/check_v26_contracts.py
run_step "V29_FEATURE_CONTRACTS" python3 scripts/check_blousab_v29.py
run_step "V29_COMPILE_REGRESSION_GUARDS" python3 scripts/check_v29_compile_regressions.py
run_step "V30_FEATURE_CONTRACTS" python3 scripts/check_v30_contracts.py
run_step "V31_SOURCE_CONTRACTS" python3 scripts/check_v31_contracts.py
run_step "V31_HOTSPOT_KOTLIN_NULL_SAFETY" python3 scripts/check_v31_hotspot_kotlin.py
run_step "PRODUCTION_SECURITY_GATE" python3 scripts/check_production_security.py
if command -v flutter >/dev/null 2>&1; then
    run_step "FLUTTER_PUB_GET" flutter pub get
    run_step "RECORD_DEPENDENCY_RESOLVED" python3 scripts/check_record_dependencies.py
    # Compile despite independent production security gate failures.
    run_step "FLUTTER_ANALYZE" flutter analyze --no-fatal-infos --no-fatal-warnings
    run_step "FLUTTER_TEST" flutter test
    run_step "FLUTTER_BUILD_APK_DEBUG" flutter build apk --debug
else
    echo "FAIL: Flutter SDK was not found in PATH; cannot verify the Android build"
    fail=$((fail + 1)); skip=$((skip + 4))
fi
printf '\n========== ACCEPTANCE SUMMARY ==========\nPASS=%s FAIL=%s SKIPPED=%s\n' "$pass" "$fail" "$skip"
if [ "$fail" -gt 0 ]; then
    echo 'The build is NOT verified. Read the failing lines above.'
    if [ -t 0 ]; then read -r -p 'اضغط Enter لإغلاق الفحص... ' _ || true; fi
    exit 1
fi
echo 'All available checks passed.'
