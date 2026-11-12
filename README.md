# Media Knowledge client

Flutter application shell for Android, iOS, macOS and Windows. Includes stable release discovery and direct installer downloads. The media library and player are planned separately.

## Development

Flutter 3.44.4 / Dart 3.12.2. Run `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, then `flutter run` on a supported platform.

## Server connection

Enter the private HTTPS origin of the Tailscale service in the app and press Connect. The address is saved locally after a successful readiness check. Each device needs Tailscale access. No personal hostname is embedded in the public build.

## Releases

Set `version: X.Y.Z+N` in pubspec.yaml, increment N, commit and push tag `vX.Y.Z`. GitHub Actions builds all four platforms. Android APK uses a persistent release keystore stored in GitHub secrets. The release contains APK, macOS DMG, Windows installer, SHA256SUMS and update-manifest.json.

The main screen displays the installed version and build number from package metadata, including when update checks fail. The running app checks stable releases at startup, resume and every four hours. Manual checks show a progress indicator, disable the check button while a request is running, and confirm the result in a snackbar, including when no update is available or the request fails. It offers the installer matching the OS and opens the direct HTTPS download in the system browser. Installation requires user confirmation. Checksums are published for manual verification; the app does not claim to verify an installer downloaded by the browser.

The macOS DMG includes installation instructions, an arrow and an Applications shortcut. Drag the app to Applications for a new install. If an earlier copy is in `~/Applications`, replace it in that folder instead to avoid two installed copies. The package layout is built by `packaging/macos/package.sh` with the macOS system tools.

macOS and Windows packages are unsigned. iOS is compiled without signing for CI only; it is not an installable IPA and is excluded from the update manifest. Apple Developer, signing and TestFlight remain to be connected. No app-store delivery is configured.

## Project and operations

[Architecture and infrastructure](https://github.com/ZeraiGR/media-knowledge) · [Release and deployment guide](https://github.com/ZeraiGR/media-knowledge/blob/main/docs/infrastructure.md) · [GitHub Project](https://github.com/users/ZeraiGR/projects/1) · [Detailed documentation](https://github.com/ZeraiGR/personal-docs/tree/main/src/content/docs/personal/media-knowledge)

Secrets, private deployment addresses, owner media and local AI models stay outside Git.
