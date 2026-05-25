#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PRODUCT="${PRODUCT:-SimpleSwiftUIApp}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SIMULATOR_NAME="${SIMULATOR_NAME:-}"
SCHEME="${SCHEME:-}"
BUNDLE_ID="${BUNDLE_ID:-app-swift.SimpleSwiftUIApp}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-17.0}"

mkdir -p "$ROOT_DIR/.build/cache" "$ROOT_DIR/.build/module-cache" "$ROOT_DIR/.build/clang-module-cache"
export SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH:-$ROOT_DIR/.build/cache}"
export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"

log() {
  printf '==> %s\n' "$*" >&2
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

first_match() {
  find . -maxdepth 3 -name "$1" -print -quit
}

swiftpm_product_exists() {
  swift package dump-package 2>/dev/null | /usr/bin/python3 -c '
import json
import sys

product = sys.argv[1]
data = json.load(sys.stdin)
for entry in data.get("products", []):
    if entry.get("name") == product and "executable" in entry.get("type", {}):
        sys.exit(0)
sys.exit(1)
' "$PRODUCT"
}

run_swift_package() {
  command_exists swift || fail "Swift is not installed or is not on PATH."
  swiftpm_product_exists || fail "No executable Swift package product named '$PRODUCT'. Set PRODUCT=<name> to choose another product."

  log "Building Swift package product '$PRODUCT'"
  swift build --product "$PRODUCT"

  log "Running '$PRODUCT'"
  swift run "$PRODUCT"
}

target_arch() {
  case "$(uname -m)" in
    arm64) printf 'arm64\n' ;;
    *) printf 'x86_64\n' ;;
  esac
}

write_simulator_info_plist() {
  local app_dir="$1"

  cat > "$app_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$PRODUCT</string>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$PRODUCT</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
  </dict>
  <key>UILaunchScreen</key>
  <dict/>
</dict>
</plist>
PLIST
}

run_swift_package_on_simulator() {
  command_exists xcrun || fail "xcrun is not installed or Xcode command line tools are not configured."
  command_exists swift || fail "Swift is not installed or is not on PATH."
  swiftpm_product_exists || fail "No executable Swift package product named '$PRODUCT'. Set PRODUCT=<name> to choose another product."

  local simulator_id sdk_path arch app_dir executable
  simulator_id="$(boot_simulator)"
  sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
  arch="$(target_arch)"
  app_dir="$ROOT_DIR/.build/ios-simulator/$PRODUCT.app"
  executable="$app_dir/$PRODUCT"

  rm -rf "$app_dir"
  mkdir -p "$app_dir"
  write_simulator_info_plist "$app_dir"

  log "Building '$PRODUCT' as an iOS Simulator app bundle"
  xcrun --sdk iphonesimulator swiftc \
    -target "$arch-apple-ios${IOS_DEPLOYMENT_TARGET}-simulator" \
    -sdk "$sdk_path" \
    -parse-as-library \
    -Onone \
    -g \
    -module-cache-path "$ROOT_DIR/.build/module-cache" \
    "$ROOT_DIR"/Sources/*.swift \
    -o "$executable"

  codesign --force --sign - --timestamp=none "$app_dir"

  log "Installing '$PRODUCT' on simulator"
  xcrun simctl install "$simulator_id" "$app_dir"

  log "Launching '$BUNDLE_ID'"
  xcrun simctl terminate "$simulator_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$simulator_id" "$BUNDLE_ID"
}

pick_simulator() {
  xcrun simctl list devices available -j | /usr/bin/python3 -c '
import json
import sys

preferred_name = sys.argv[1]
devices_by_runtime = json.load(sys.stdin).get("devices", {})
booted = []
available = []

for runtime, devices in devices_by_runtime.items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        if not device.get("isAvailable"):
            continue
        if preferred_name and device.get("name") != preferred_name:
            continue
        target = {"name": device.get("name"), "udid": device.get("udid"), "state": device.get("state")}
        if device.get("state") == "Booted":
            booted.append(target)
        available.append(target)

choices = booted or available
if not choices:
    sys.exit(1)

print(choices[0]["udid"])
' "$SIMULATOR_NAME"
}

boot_simulator() {
  command_exists xcrun || fail "xcrun is not installed or Xcode command line tools are not configured."

  local simulator_id
  simulator_id="$(pick_simulator)" || fail "No available iOS simulator found. Install an iOS simulator runtime in Xcode."

  log "Booting simulator $simulator_id if needed"
  xcrun simctl boot "$simulator_id" >/dev/null 2>&1 || true

  log "Opening Simulator.app"
  open -a Simulator

  printf '%s\n' "$simulator_id"
}

default_scheme() {
  local container_flag="$1"
  local container_path="$2"

  xcodebuild -list "$container_flag" "$container_path" -json |
    /usr/bin/python3 -c '
import json
import sys

data = json.load(sys.stdin)
project = data.get("project", {})
workspace = data.get("workspace", {})
schemes = project.get("schemes") or workspace.get("schemes") or []
if not schemes:
    sys.exit(1)
print(schemes[0])
'
}

app_bundle_id() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Info.plist"
}

run_xcode_on_simulator() {
  local workspace project container_flag container_path simulator_id app_path bundle_id

  workspace="$(first_match '*.xcworkspace')"
  project="$(first_match '*.xcodeproj')"

  if [[ -n "$workspace" ]]; then
    container_flag="-workspace"
    container_path="$workspace"
  elif [[ -n "$project" ]]; then
    container_flag="-project"
    container_path="$project"
  else
    fail "No Xcode project or workspace found."
  fi

  if [[ -z "$SCHEME" ]]; then
    SCHEME="$(default_scheme "$container_flag" "$container_path")" || fail "Could not infer an Xcode scheme. Set SCHEME=<name>."
  fi

  simulator_id="$(boot_simulator)"

  log "Building scheme '$SCHEME' for iOS Simulator"
  xcodebuild \
    "$container_flag" "$container_path" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "id=$simulator_id" \
    build

  app_path="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/${CONFIGURATION}-iphonesimulator/*.app" -name "${SCHEME}.app" -print -quit)"
  if [[ -z "$app_path" ]]; then
    app_path="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/${CONFIGURATION}-iphonesimulator/*.app" -print -quit)"
  fi
  [[ -n "$app_path" ]] || fail "Build succeeded, but no simulator .app was found in DerivedData."

  bundle_id="$(app_bundle_id "$app_path")"

  log "Installing '$app_path'"
  xcrun simctl install "$simulator_id" "$app_path"

  log "Launching '$bundle_id'"
  xcrun simctl terminate "$simulator_id" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl launch "$simulator_id" "$bundle_id"
}

case "${1:-auto}" in
  auto)
    if [[ -f Package.swift ]] && swiftpm_product_exists; then
      run_swift_package
    else
      run_xcode_on_simulator
    fi
    ;;
  mac|swiftpm)
    run_swift_package
    ;;
  ios|sim|simulator)
    if [[ -f Package.swift ]] && swiftpm_product_exists && [[ -z "$(first_match '*.xcworkspace')" ]] && [[ -z "$(first_match '*.xcodeproj')" ]]; then
      run_swift_package_on_simulator
    else
      run_xcode_on_simulator
    fi
    ;;
  *)
    cat <<'USAGE'
Usage: scripts/check-and-run.sh [auto|mac|swiftpm|ios|sim|simulator]

Environment:
  PRODUCT=<SwiftPM executable product>  Default: SimpleSwiftUIApp
  SCHEME=<Xcode scheme>                Required only if a scheme cannot be inferred
  CONFIGURATION=<Debug|Release>        Default: Debug
  SIMULATOR_NAME=<simulator name>      Optional, for example "iPhone 16 Pro"
  BUNDLE_ID=<bundle identifier>        Default: app-swift.SimpleSwiftUIApp
USAGE
    exit 64
    ;;
esac
