#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf '%s\n' 'Build on macOS 13+ with a compatible Swift 5.9+ toolchain.' >&2
    exit 1
fi
configuration="${CONFIGURATION:-release}"
if [[ "$configuration" != "release" && "$configuration" != "debug" ]]; then
    printf '%s\n' 'CONFIGURATION must be release or debug.' >&2
    exit 1
fi
build_directory="${BUILD_DIRECTORY:-.build}"
xcrun swift build --disable-sandbox --scratch-path "$build_directory" -c "$configuration" --product PDFTextCleaner
binary_directory="$(xcrun swift build --disable-sandbox --scratch-path "$build_directory" -c "$configuration" --show-bin-path)"
app="${APP_OUTPUT:-dist/PDF Text Cleaner.app}"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_directory/PDFTextCleaner" "$app/Contents/MacOS/PDFTextCleaner"
if [[ "$configuration" == "release" ]]; then
    # Swift's debug map includes absolute source paths; remove it before signing.
    xcrun strip -S "$app/Contents/MacOS/PDFTextCleaner"
    if LC_ALL=C grep -aEq '/(Users|home)/' "$app/Contents/MacOS/PDFTextCleaner"; then
        printf '%s\n' 'Release binary contains a local home-directory path.' >&2
        exit 1
    fi
fi
cp Resources/Info.plist "$app/Contents/Info.plist"
cp -R Resources/*.lproj "$app/Contents/Resources/"
plutil -lint "$app/Contents/Info.plist"
codesign --force --sign "${SIGNING_IDENTITY:--}" "$app"
codesign --verify --strict "$app"
printf '\nBuilt: %s\n' "$app"
