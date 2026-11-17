# Dog Gram

Dog Gram is an unofficial Telegram iOS client fork with a local visual customization layer. Dog Gram is built directly from the native Telegram-iOS source in this repository.

## Native integration in this step

- Triple-tapping the Chats tab opens **Dog Gram Control**.
- The control panel contains Profile, NFT usernames, Gifts, Appearance, Balances and demo operation history.
- Profile controls include a local photo-library avatar, demo Premium/check toggles, demo verification and level, and a local display number. The self-profile header shows these values with a clear Dog Gram Visual · DEMO label.
- Local NFT usernames accept a name, price and currency. Demo gifts show a preview and require confirmation before being added locally.
- Demo balances and custom assets are editable and saved with `UserDefaults`.
- Appearance color, background label, theme, working hours and address are stored locally. The color selection updates a local preview.
- The existing Telegram chats, messages, groups, channels, contacts, calls and settings continue to come from upstream Telegram-iOS.

Nothing in the Dog Gram visual settings is sent to Telegram. The gift and balance demo flows do not make purchases, send assets or represent real financial operations.

## Build and signing

This checkout runs on Windows and has no Xcode. Xcode is a macOS tool; Apple publishes Xcode with supported macOS versions, not a Windows installer. This repository pins Xcode 27.1 in `versions.json` and builds through Bazel and `Make.py`.

### Build the IPA on a Mac

1. Use a Mac that can run the Xcode version pinned in `versions.json`, locally or through a remote Mac service.
2. Copy `build-system/doggram-development-configuration.example.json` to `build-system/doggram-local-configuration.json` (this local file is ignored by Git). Add your own Telegram API ID/hash, Apple Team ID, and confirm `org.doggram.ios` is available to your team. Telegram requires third-party clients to use their own API ID; you can create one at [my.telegram.org](https://my.telegram.org).
3. Create the matching signing certificate and provisioning profiles on that Mac. For a device build, follow the `release_arm64` instructions in this repository's `README.md`.
4. From the repository root, run:

   ```sh
   python3 build-system/Make/Make.py \
     --cacheDir="$HOME/doggram-bazel-cache" \
     build \
     --configurationPath=build-system/doggram-local-configuration.json \
     --codesigningInformationPath=/path/to/your/signing-data \
     --buildNumber=1 \
     --configuration=release_arm64
   ```

   After a successful build, the upstream script puts the IPA at `bazel-bin/Telegram/Telegram.ipa`.

### Install from Windows

Sideloadly runs on Windows and can sign/install an existing IPA; it does not compile the Swift project. Sideloadly's FAQ says a free Apple account signature lasts 7 days and permits 3 sideloaded apps. A paid Apple Developer account can sign for longer. Keep the signing certificate, provisioning profile, API hash and Apple credentials on the Mac or in private CI secrets; do not commit them.

GitHub Actions uses Telegram's public fake-signing fixtures to build a device IPA without the user's Apple Team ID. The IPA is not trusted by iOS and must be re-signed with Sideloadly or another signing tool before installation. Push notifications and other Apple-managed capabilities won't work without matching Apple signing entitlements. The standard Apple Silicon runner has 7 GB RAM, so a full Bazel build may exceed the available memory.

### GitHub Actions setup

The manual workflow is in `.github/workflows/doggram-ipa.yml`. Add these repository secrets in **Settings → Secrets and variables → Actions**:

- `DOGGRAM_API_ID`
- `DOGGRAM_API_HASH`

Then open **Actions → Dog Gram IPA → Run workflow** and choose `debug_arm64`. GitHub uploads the fake-signed IPA as a downloadable workflow artifact. Download it to Windows and re-sign/install it with Sideloadly. The workflow is manual-only so a code push does not start a paid Mac build.

## Work still needed

The live profile metadata bridge and first local control flows are in place. Applying the local avatar and background image directly to the Telegram self-profile, richer NFT cover management, a complete gift catalog, and supported real Telegram gift API integration still need work. The icon now uses a Dog Gram vector mark instead of Telegram's airplane. The source has not been compiled because this Windows environment does not include Xcode.

## Source

Upstream Telegram-iOS: https://github.com/TelegramMessenger/Telegram-iOS
