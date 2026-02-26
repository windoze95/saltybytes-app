# Integration Tests

End-to-end tests that launch the full SaltyBytes app on a simulator or device
and exercise core user flows against the **live production API**.

## What's Tested

| # | Flow               | What it verifies                                                      |
|---|--------------------|-----------------------------------------------------------------------|
| 1 | **Login**          | Enters credentials, taps Sign In, navigates to home                   |
| 2 | **Home screen**    | Recipe grid renders with titles, cook times, servings                 |
| 3 | **Recipe detail**  | Taps a card → detail loads ingredients & instructions (no type-cast crash) |
| 4 | **Bottom nav**     | Cycles through Search, Family, Settings tabs                          |
| 5 | **Add Recipe**     | FAB opens bottom sheet with "Generate with AI" / "Import from URL"    |
| 6 | **Import screen**  | All 4 import options render (URL, Photo, Text, Manual Entry)          |

## Prerequisites

- **iOS Simulator** booted (or a physical device connected)
- **Production API** (`https://api.saltybytes.ai`) must be reachable
- **Test account** — see `_kUsername` / `_kPassword` constants in `app_test.dart`

## Running

```bash
# On the default connected device / simulator
flutter test integration_test/app_test.dart

# On a specific simulator (use `xcrun simctl list devices booted` to find the ID)
flutter test integration_test/app_test.dart -d <DEVICE_ID>
```

## Taking Screenshots While Tests Run

The tests signal their progress via debug prints. You can capture simulator
screenshots in parallel by watching the console output:

```bash
# In a separate terminal, take a screenshot at any time:
xcrun simctl io booted screenshot /tmp/screenshot.png
```

## Notes

- Tests skip the login step if the app already has a valid session (e.g. from
  a previous run on the same simulator).
- `_pumpUntilSettled` handles looping animations (shimmer/skeleton loaders)
  gracefully by retrying with a timeout instead of throwing.
- The tests run against the live API — they do **not** mock network calls.
  This means they prove the full backend ↔ frontend contract is working.
