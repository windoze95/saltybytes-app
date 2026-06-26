# Wake-word models ("Hey Salty")

Cooking mode uses [Picovoice Porcupine](https://picovoice.ai/platform/porcupine/)
for on-device "Hey Salty" wake-word detection
(`lib/core/voice/wake_word_service.dart`). Until the two items below are in
place, the engine reports `isConfigured == false` and hands-free gracefully
falls back to tap-to-talk (the mic button captures one command).

## 1. Access key

Create a free account at https://console.picovoice.ai and copy your **AccessKey**.
Supply it at build time:

```
flutter run   --dart-define=PICOVOICE_ACCESS_KEY=<your-key>
flutter build ipa --dart-define=PICOVOICE_ACCESS_KEY=<your-key> ...
```

For CI/TestFlight, store it as the `PICOVOICE_ACCESS_KEY` repo secret — it is
already passed through in `.github/workflows/testflight.yml`.

## 2. "Hey Salty" keyword models

In the Picovoice Console, train a **custom wake word** ("Hey Salty") and download
a `.ppn` model for **each platform**, then drop them here with these exact names:

```
assets/wake/hey_salty_ios.ppn       # platform target: iOS
assets/wake/hey_salty_android.ppn   # platform target: Android
```

They are bundled automatically (this directory is listed under `flutter: assets`
in `pubspec.yaml`). `.ppn` files are platform-specific — an iOS model will not
load on Android.

## Notes

- Free Picovoice accounts have monthly active-user limits; review pricing before
  production.
- The microphone permission is already declared (iOS `Info.plist`).
- To change the phrase, retrain the keyword and update the filenames in
  `PorcupineWakeWordService._defaultKeywordAssets`.
