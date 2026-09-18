# PDF Text Cleaner

[简体中文](README.zh-CN.md)

A native macOS menu bar utility that joins unwanted line breaks in copied PDF text, preserves blank-line paragraphs and common lists, and shows the original beside an editable result.

## Download

Get the macOS ZIP from this repository's **Releases**, extract it, and open **PDF Text Cleaner.app**. You can move it to Applications. Click the text/checkmark icon in the menu bar; the app does not appear in the Dock or start at login.

The provided binary requires **Apple Silicon and macOS 13+**. Intel users can build from source. Releases are ad hoc signed, not Developer ID signed or notarized; macOS may require explicit approval to open a downloaded build.

## Automatic mode

**Auto-clean clipboard is on by default**, and your on/off preference is remembered. Copy multiline text, wait about half a second, then paste directly into any app. The panel need not be open.

Changed content becomes **plain text**, removing rich formatting. Single-line text, unchanged results, files, images, multiple clipboard items, and content marked concealed/transient/generated are skipped. Existing clipboard contents stay unchanged when the app launches or the feature is enabled.

The panel shows the most recent automatically cleaned text. **Restore last copy** restores its original text and clipboard formats while that automatic result is still on the clipboard. It never replaces a newer copy, and restored content is not immediately cleaned again.

This applies to supported multiline copies from any app, not only PDFs. Turn it off for code, poetry, or addresses where line breaks matter. If macOS asks for clipboard access, that access is needed for automatic mode.

## Manual mode and cleanup rules

Disable **Auto-clean clipboard**, then click **Paste text** or paste into the left editor. Review or edit the right editor, then use **Copy result** or **⇧⌘C**. **Try example** loads a localized sample.

- Blank lines separate paragraphs; common numbered and bulleted list items stay on separate lines.
- Chinese lines join without added spaces; English words keep their separating spaces.
- **Repair hyphenated words** is off by default. It joins `inter-` + newline + `national`, but may also remove intentional hyphens.
- Editing the source or cleanup options regenerates the result and replaces manual edits in the right editor.
- Without blank lines, original paragraph boundaries cannot be reliably inferred; add them or adjust the result.

## Language and privacy

The interface follows the system's preferred supported language: **English, Simplified Chinese, or Traditional Chinese**, falling back to English. Restart after changing the language. The source text is not translated.

Text processing is local: no network requests, analytics, or clipboard history files. The latest original/result and last restorable copy stay in memory only. Only the automatic-mode preference is saved. The app does not request screen recording or accessibility access.

## Try it

Copy [Examples/before.txt](Examples/before.txt), wait briefly, and paste into a plain-text editor. Compare with [Examples/after.txt](Examples/after.txt), ignoring a final newline.

## Build and check

Requires macOS 13+ and a compatible **Swift 5.9+** toolchain (Xcode or Command Line Tools). No third-party dependencies.

```bash
swift run --disable-sandbox CleanerChecks
swift scripts/check-localizations.swift
bash scripts/build.sh
open "dist/PDF Text Cleaner.app"
```

Clipboard checks use a unique test pasteboard, never the general clipboard. GitHub Actions runs checks and builds on pushes and pull requests. Builds target the current Mac's architecture.

Optional environment variables: `CONFIGURATION=debug`, `SIGNING_IDENTITY`, `APP_OUTPUT`, and `BUILD_DIRECTORY`.

Release builds remove debug symbols before signing and reject binaries containing home-directory paths. To package the default release build without macOS file metadata:

```bash
ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "dist/PDF Text Cleaner.app" "dist/PDF-Text-Cleaner.zip"
```
