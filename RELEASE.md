# Release Documentation: Zenith Zero

## Project Metadata
- **App Name:** Zenith Zero
- **Bundle ID (iOS/macOS):** `com.twang.zenithzero`
- **Package Name (Android):** `com.twang.zenithzero`
- **Version:** `1.0.0+1`

## Build Instructions

### iOS (TestFlight)
1.  **Generate IPA:**
    ```bash
    flutter build ipa
    ```
2.  **Upload:**
    - Open **Transporter** app.
    - Drag `build/ios/ipa/flame_game.ipa` into Transporter.
    - Click **Deliver**.
3.  **Distribute:**
    - Go to [App Store Connect](https://appstoreconnect.apple.com/).
    - Select **Zenith Zero**.
    - Manage testers in the **TestFlight** tab.

### Android
1.  **Generate APK:**
    ```bash
    flutter build apk
    ```
    - Output: `build/app/outputs/flutter-apk/app-release.apk`
2.  **Generate App Bundle (for Play Store):**
    ```bash
    flutter build appbundle
    ```
    - Output: `build/app/outputs/bundle/release/app-release.aab`

## Assets & Branding
- **Icon Source:** `~/Downloads/images/idle-tower-def-pixel-style-game-mobile-app-icon--n.png`
- **Tools Used:**
    - `flutter_launcher_icons`: Generates platform-specific app icons.
    - `flutter_native_splash`: Generates the initial splash screen.

## Distribution Checklist
- [ ] Create App Record in App Store Connect with ID `com.twang.zenithzero`.
- [ ] Create App Record in Google Play Console with ID `com.twang.zenithzero`.
- [ ] Verify Splash Screen on physical device/emulator.
- [ ] Run `flutter analyze` and `flutter test` before final archival.

## Changelog

### v1.1.0
- **Combat Evolution:** Overhauled Sentinel Blades into "Celestial Jian" (yujian-style flying swords) with aggressive sweep pathing and "Endless Seek" logic.
- **Visual Fidelity:** Added ethereal gradient trails and improved alignment for high-speed projectiles.
- **Performance:** Optimized render paths with Paint caching and capped spark effects for stable frame rates.
- **Build System:** Migrated iOS/macOS to Swift Package Manager (SPM), removing CocoaPods dependency.
- **Developer Tools:** Added in-game upgrade toggles for rapid testing of late-game combat states.

### v1.0.0
- **Rebrand:** Officially launched as "Zenith Zero".
- **Meta-Progression:** Introduced Embers, boons, and archetype keystones for deep long-term progression.
- **Stability:** Resolved memory issues (OOM) by implementing static TextPaint caching and efficient enemy tracking.
- **Visual Progression:** Implemented Skill Evolution system where effects gain visual flourishes and complexity as they level up.
- **Minimalist Aesthetic:** Refactored all game entities to use a refined, shape-rendered minimal art style.
