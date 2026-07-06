# Store release playbook

How app builds reach TestFlight and Google Play, what signing material exists, and the one-time
console setup each store needs. CI automates everything that can be automated; the remaining
human steps are listed explicitly. Versioning: bump `version:` in `pubspec.yaml` for a
user-facing version change — build numbers are computed per store by CI (TestFlight: commit
count since the version was set; Play: max version code across tracks + 1). The two counters
are independent, which is fine — stores only compare within themselves.

## ⚠️ Launch blockers (before PRODUCTION review — closed testing is unaffected)

1. **In-app account deletion does not exist** (no API endpoint, no UI). Apple **requires** it
   for any app with account creation (Guideline 5.1.1(v)) and Play's Data safety form asks for
   a deletion path. The privacy policy's email-based deletion covers the interim/Play-URL case,
   but iOS production review will bounce without the in-app flow. Build it first.
2. **Premium upgrade bypasses IAP.** `SubscriptionScreen` calls `POST /v1/subscription/upgrade`
   directly — a digital purchase outside StoreKit/Play Billing is an automatic rejection
   (Apple 3.1.1 / Play Payments policy). Before submitting: either integrate store billing, or
   hide the upgrade CTA in store builds (everyone stays free-tier) and revisit.
3. **Reviewer demo account.** Both stores need working credentials in the review notes (the app
   is login-gated). Create a dedicated `appreview` account with a few saved recipes and keep it
   working.
4. `https://saltybytes.ai` doesn't resolve yet — listings point at the GitHub repo for
   marketing/support and the in-repo privacy policy. Swap to the real site when it exists.

## Android (Google Play)

### Pipeline

`.github/workflows/playstore.yml` runs on every merge to `main` that touches Android-relevant
paths (ios/web/test/tool/docs excluded), and on manual dispatch (inputs: track
`alpha`/`internal`, release status `completed`/`draft`).

1. Version code = max version code across all Play tracks + 1 (`next_build_number` lane in
   `android/fastlane/Fastfile`); version name = `pubspec.yaml` version minus the `+` suffix.
2. The AAB is signed with the upload keystore from the `ANDROID_KEYSTORE_*` secrets, built with
   `--dart-define=SALTYBYTES_ID` (same identity header as the iOS build), and attached to the
   run as an artifact — every run, upload or not.
3. With `PLAY_SERVICE_ACCOUNT_JSON` set, the `beta` lane uploads the AAB to the Play **alpha**
   track ("Closed testing - Alpha" — Google's pre-made closed track; the id `beta` is reserved
   for open testing). Without it, the upload is skipped and the run stays green.

PRs touching `android/**`, `pubspec.yaml`, or the workflow get a build-only check (signed AAB
artifact, no upload). Runs are serialized (`concurrency: playstore-deploy`) because two
concurrent runs would compute the same version code.

### Signing material

| Secret | Contents | Status |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | base64 of `upload-keystore.jks` | ✅ set 2026-07-05 |
| `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_PASSWORD` | keystore/key password (same value; PKCS12) | ✅ set |
| `ANDROID_KEY_ALIAS` | `upload` | ✅ set |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Cloud service-account JSON key with Play publish access | ⬜ set after console setup (below) |

The keystore is only the Play **upload key** — Google Play App Signing holds the actual app
signing key, so a lost upload key is recoverable (Play Console → "Request upload key reset").
The `.jks` and password live outside the repo at `~/Projects/SaltyBytes/release-keys/` (back
them up to a password manager). Upload-key SHA-256 is in that directory's README. Never commit
either; `android/.gitignore` already ignores `key.properties` and `*.jks`.

For anything needing the real distribution certificate later (app links, passkeys), use the
**Play app-signing** SHA-256 from Play Console → App integrity — not the upload key's.

### One-time Play Console setup (human)

1. Play Console → **Create app** — name `SaltyBytes`, free app. The package name binds as
   `codes.julian.saltybytes` on first upload and can never change.
2. Download the `.aab` artifact from any **Deploy to Play Store** run. The very first bundle of
   a new app must be uploaded by hand (the publisher API can't create it): Testing → Closed
   testing → manage the pre-made "Closed testing - Alpha" track → create release → upload the
   AAB. Accepting Play App Signing here enrolls the upload key.
3. Service account — reuse the one already publishing Cantinarr
   (`play-publisher@ferrous-acronym-501521-n3.iam.gserviceaccount.com`; key archived at
   `~/Projects/Cantinarr/release-keys/play-service-account.json`): Play Console → Users and
   permissions → that account → grant app access to SaltyBytes (release-to-testing-tracks or
   app-level Admin). Same Play developer account, so no new GCP setup is needed.
4. `gh secret set PLAY_SERVICE_ACCOUNT_JSON --repo windoze95/saltybytes-app < ~/Projects/Cantinarr/release-keys/play-service-account.json`
   — from here on, every merge to `main` ships to closed testing automatically, and
   `storelisting.yml` can push the Play listing.
5. Finish the console forms (prepared answers below) before promoting beyond testing.
6. Closed testing → Testers: add an email list and share the opt-in link.

Personal developer accounts created after Nov 13, 2023 must run a closed test with **12+
opted-in testers for 14 continuous days** before applying for production access (the alpha
track satisfies this; the console dashboard tracks progress).

### Google Play console forms — prepared answers

Unlike a self-hosted client, SaltyBytes **does** operate a backend and collects real user data.
Answer honestly:

- **Data safety** — "Does your app collect or share any of the required user data types?" →
  **Yes.** Collected, not shared (processors acting on our instructions don't count as
  sharing); all traffic encrypted in transit; deletion via the privacy policy's email path
  (link `https://github.com/windoze95/saltybytes-app/blob/main/docs/privacy-policy.md`):
  - *Personal info → Email address, User IDs (username)* — required, account management.
  - *Health info → Other health info* — **optional**, app functionality (family dietary/allergy
    profiles the user chooses to add).
  - *Photos and videos → Photos* — optional, app functionality (cookbook-photo import).
  - *Audio → Voice or sound recordings* — optional, app functionality (voice import /
    hands-free cooking; transcribed, recordings not retained).
  - *App activity → App interactions* — app functionality + analytics (first-party operational
    telemetry; no third-party analytics SDKs).
  - Ads: **No.** Data sold: **No.**
- **Content rating (IARC)**: category "Utility, Productivity, Communication, or Other". No
  violence/sexuality/gambling. "Does the app contain user-generated content shared with other
  users?" → **No** (recipes are private to the account). Alcohol: recipes *may* reference
  alcohol as ingredients — answer the alcohol-reference question Yes if asked (still lands
  Everyone/PEGI 3-ish; expected rating: Everyone).
- **Target audience**: 18+ (do not tick under-13 bands — that triggers Families policy).
- **Privacy policy URL**:
  `https://github.com/windoze95/saltybytes-app/blob/main/docs/privacy-policy.md`
- **App category**: Food & Drink. Contact email: windoze95@proton.me.
- **Account deletion**: point at the privacy policy (email path) until in-app deletion ships.

## Store listings (both stores)

Listing copy, graphics, and screenshots are code, managed with fastlane's layouts:

- Play: `android/fastlane/metadata/android/en-US/` — `title.txt` (30 chars max),
  `short_description.txt` (80), `full_description.txt` (4000), `changelogs/default.txt`
  ("what's new", rides along with every AAB upload), `images/icon.png` (512×512),
  `images/featureGraphic.png` (1024×500), `images/phoneScreenshots/`,
  `images/tenInchScreenshots/`.
- App Store: `ios/fastlane/metadata/en-US/` — `name.txt` (30), `subtitle.txt` (30),
  `description.txt` (4000), `keywords.txt` (100), `promotional_text.txt` (170),
  `release_notes.txt`, `support_url.txt`, `marketing_url.txt`, `privacy_url.txt`,
  `copyright.txt`; categories in `ios/fastlane/metadata/{primary,secondary}_category.txt`;
  screenshots in `ios/fastlane/screenshots/en-US/` (device class inferred from pixel size:
  1320×2868 = iPhone 6.9", 2064×2752 = iPad 13").

`.github/workflows/storelisting.yml` pushes the listings to both consoles whenever a merge to
`main` touches those paths (and via manual dispatch with a platform picker). Play sync skips
gracefully until `PLAY_SERVICE_ACCOUNT_JSON` exists; App Store sync uses the existing
`APP_STORE_CONNECT_*` secrets.

To change store copy: edit the fastlane files and merge — never edit the consoles by hand.

### Screenshots

Store screenshots are generated, not hand-taken:

1. `test/preview/screenshot_main.dart` boots the real app (theme, shell nav, Search, Home,
   detail, Family, Import, preview) with a stubbed backend returning rich demo payloads —
   including the agent-search SSE stream. Demo photos live in `tool/screenshots/demo/`
   (Unsplash-licensed; credits in `CREDITS.md`).
2. `tool/screenshots/build.sh` builds the web harness, serves it with the demo images, drives
   system Chrome via Playwright at exact store pixel sizes (`shoot.js` + `routes.js`: iPhone
   6.9" 1320×2868, iPad 13" 2064×2752, Play phone 1080×2400, Play tablet 1600×2560), and
   renders the 1024×500 feature graphic from `featuregraphic.html`.
3. `tool/screenshots/collect.sh` copies the outputs into the two fastlane screenshot
   directories. Commit; the merge syncs them to the consoles.

Iterating on one shot: `tool/screenshots/build.sh --skip-flutter-build android search_picks`.

## iOS (TestFlight / App Store)

### Pipeline

`.github/workflows/testflight.yml` (pre-existing) auto-builds to TestFlight on every push to
`main`; build number = commits since the pubspec version was set; waits for ASC processing so
green = installable. Signing via `IOS_DIST_CERT_*` / `IOS_PROVISIONING_PROFILE_BASE64` secrets.

### App Store release

Submitting for review is one workflow run: **Submit App Store Release**
(`.github/workflows/appstore-release.yml`, manual dispatch, type `submit` to confirm). It runs
the `release` lane: finds the latest processed TestFlight build of the current pubspec version
and submits it with phased release on and manual rollout off — release notes and listing
content come from the in-repo metadata. Before the *first* submission, do the one-time steps
below.

### One-time App Store Connect setup (human)

1. **App Review contact**: App Store Connect → the app → App Information / the version's App
   Review section → set contact name, email, and **phone number** (required; deliberately not
   committed — until it exists, the metadata lane skips review-detail handling via the
   fastlane#20538 shim). Add the reviewer demo account credentials to the review notes.
2. **App Privacy** (nutrition labels) — data **linked to you**: Email address + User ID
   (account), Photos (import), Audio (voice features), Health (family dietary profiles —
   user-provided, optional), User content (recipes), Product interaction (first-party
   telemetry). Not used for tracking; no third-party ads/analytics.
3. **Age rating questionnaire**: all descriptors None except "Alcohol, Tobacco, or Drug Use or
   References" → *Infrequent/Mild* (user-imported recipes can include cocktails) → lands 12+.
   Unrestricted web access: No.
4. **App availability + price** (free), and confirm the primary category (Food & Drink).

## Secret rotation

- Upload keystore: regenerate + `gh secret set ANDROID_KEYSTORE_BASE64` etc., then Play Console
  → App integrity → Request upload key reset.
- Play service account: new JSON key in GCP → update `PLAY_SERVICE_ACCOUNT_JSON`.
- App Store Connect API key / dist cert / profile: same secrets as TestFlight (see
  `testflight.yml`).
