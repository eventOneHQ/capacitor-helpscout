<p align="center"><br><img src="https://user-images.githubusercontent.com/236501/85893648-1c92e880-b7a8-11ea-926d-95355b8175c7.png" width="128" height="128" /></p>
<h3 align="center">Capacitor Help Scout</h3>
<p align="center"><strong><code>capacitor-helpscout</code></strong></p>
<p align="center">
  Capacitor plugin for <a href="https://developer.helpscout.com/beacon-2/mobile/">Help Scout Beacon</a> (unofficial)
</p>

<p align="center">
  <img src="https://img.shields.io/maintenance/yes/2026?style=flat-square" />
  <a href="https://github.com/eventOneHQ/capacitor-helpscout/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/eventOneHQ/capacitor-helpscout/release.yml?style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/capacitor-helpscout"><img src="https://img.shields.io/npm/l/capacitor-helpscout?style=flat-square" /></a>
<br>
  <a href="https://www.npmjs.com/package/capacitor-helpscout"><img src="https://img.shields.io/npm/dw/capacitor-helpscout?style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/capacitor-helpscout"><img src="https://img.shields.io/npm/v/capacitor-helpscout?style=flat-square" /></a>
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
<a href="#contributors-"><img src="https://img.shields.io/badge/all%20contributors-0-orange?style=flat-square" /></a>
<!-- ALL-CONTRIBUTORS-BADGE:END -->
</p>

## Requirements

- **Capacitor**: 8.x
- **Help Scout Beacon SDK**:
  - iOS: 4.1.0 (requires iOS 15.0+ and Xcode 26+)
  - Android: 7.0.2 (requires Android API 24+)

## Maintainers

| Maintainer | GitHub                              | Social                                      |
| ---------- | ----------------------------------- | ------------------------------------------- |
| Noah Prail | [nprail](https://github.com/nprail) | [@NoahPrail](https://twitter.com/NoahPrail) |

## Installation

Using npm:

```bash
npm install capacitor-helpscout
```

Using yarn:

```bash
yarn add capacitor-helpscout
```

Sync native files:

```bash
npx cap sync
```

## Configuration

### iOS

Add the usage descriptions Beacon needs for attachments to your `Info.plist`:

- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`

The documents picker also needs an iCloud container matching your bundle ID.

### Android

Beacon's manifest sets `android:supportsRtl="false"`, which conflicts with the `true` in Capacitor's default template. In your app's `AndroidManifest.xml` add the `tools` namespace and `tools:replace`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <application
        android:supportsRtl="true"
        tools:replace="android:supportsRtl">
```

This plugin disables Beacon's automatic initialization because `initialize()` does it. To use a different Beacon SDK version, set `helpscoutBeaconVersion` in your project's `ext` block.

## Usage

```javascript
import { HelpScout } from 'capacitor-helpscout'

// First, initialize the SDK
await HelpScout.initialize({ beaconId: 'YOUR_BEACON_ID' })

// Optionally customize Beacon (only the values you provide change)
await HelpScout.configure({ color: '#617DEC', focusMode: 'neutral' })

// Associate the session with a user
await HelpScout.identify({
  email: 'user@example.com',
  name: 'Jane Doe',
  attributes: { plan: 'pro' },
})

// Open Beacon, or jump straight to a screen
await HelpScout.open()
await HelpScout.navigate({ screen: 'askMessage' })
await HelpScout.search({ query: 'invoice' })
await HelpScout.openArticle({ articleId: 'DOCS_ARTICLE_ID' })
await HelpScout.askQuestion({ question: 'How do I reset my password?' })

// Prefill the contact form
await HelpScout.setPrefilledForm({
  subject: 'Need help with my invoice',
  customFields: { 5678: 'Question' },
})

// Listen for Beacon opening and closing
const handle = await HelpScout.addListener('beaconClosed', () => {
  console.log('Beacon closed')
})
// handle.remove() when you are done

// When the user signs out
await HelpScout.logout({ endActiveChat: true })
```

Calling any method other than `initialize` first rejects with `Beacon is not initialized`.

### Secure Mode

Compute the signature on your backend from the user's email. Pass it to `identify({ signature })`, which remembers it for later opens, searches and push handling. You can also pass it to any `open`, `navigate`, `search`, `openArticle` and `askQuestion` call. Never ship your secret key in the app.

### Push notifications

1. Ask Help Scout (help@helpscout.com) to configure APNs / FCM for your Beacon.
2. **iOS**: call `initializePushNotifications()`.
   - With `@capacitor/push-notifications` the device token is forwarded to Beacon automatically. Otherwise call `setPushToken({ token })` with the hex APNs token.
   - Automatic handling does not work in Secure Mode. Pass `methodSwizzling: false` and call `handlePushNotification({ data, signature })` yourself.
3. **Android**: call `setPushToken({ token })` with the FCM token. Beacon registers its own messaging service. Request `POST_NOTIFICATIONS` on Android 13+. For payloads you receive yourself, use `isBeaconPushNotification` and `handlePushNotification`.

### Differences between platforms

| Feature                                                               | iOS                                | Android                                                    |
| --------------------------------------------------------------------- | ---------------------------------- | ---------------------------------------------------------- |
| `localizationOverrides`, `useLocalTranslationOverrides`               | Supported                          | Ignored; override the `hs_beacon_*` string resources       |
| `beaconOpened` / `beaconClosed` `initial` flag                        | Provided                           | Not provided                                               |
| `logsEnabled`, most `getStatus()` fields                              | Ignored / omitted                  | Supported                                                  |
| Contact form overrides not specified                                  | Beacon Builder values kept         | Treated as enabled once any is set                         |
| Prefilled attachments                                                 | `data` (base64) or `file://` `uri` | `uri`, or `data` written to a temp file                    |
| `failedToRegisterForPushNotifications`, `initializePushNotifications` | Supported                          | No-op                                                      |
| `reset()` / `clear()`                                                 | `HSBeacon.reset()` / logout + reset | `contactFormReset()` / `Beacon.clear()` then re-initialize |

## API Reference

See the full API docs [here](https://eventonehq.github.io/capacitor-helpscout).

| Method                                                      | Description                                                                                                                                          |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `initialize({ beaconId, logsEnabled? })`                    | Initialize Beacon. Must be called first.                                                                                                             |
| `configure(config)`                                         | Feature toggles, `color`, `focusMode`, `contactForm` and iOS-only localization overrides.                                                            |
| `open({ signature? })` / `close()`                          | Open Beacon on its default screen, or close it.                                                                                                      |
| `navigate({ screen, signature? })`                          | Open `home`, `ask`, `askMessage`, `askChat`, `answers`, `aiAnswers` or `previousMessages`.                                                           |
| `search`, `openArticle`, `askQuestion`                      | Search Docs, open a Docs article, or submit a question to AI Answers.                                                                                |
| `identify`, `logout`, `reset`, `clear`                      | Manage the identified user and clear the contact form or all Beacon data.                                                                            |
| `addAttribute`, `removeAttribute`, `clearAttributes`        | Manage user attributes (max 30).                                                                                                                     |
| `setSessionAttributes`, `getSessionAttributes`              | Manage session attributes (max 20).                                                                                                                  |
| `setPrefilledForm`, `clearPrefilledForm`                    | Prefill the contact form, including custom fields and attachments.                                                                                   |
| `setSuggestions`, `resetSuggestions`                        | Override suggested articles and links (max 10).                                                                                                      |
| `initializePushNotifications`, `setPushToken`               | Set up push handling and give Beacon the APNs or FCM token.                                                                                          |
| `isBeaconPushNotification`, `handlePushNotification`        | Detect and handle Beacon push payloads.                                                                                                              |
| `failedToRegisterForPushNotifications`                      | Report a failed push registration. iOS only.                                                                                                         |
| `getStatus()`                                               | SDK state: `initialized`, `beaconId`, `version`, and more on Android.                                                                                |
| `addListener('beaconOpened' \| 'beaconClosed', fn)`         | Open and close events.                                                                                                                               |

## Sponsors

<p>
    <a href="https://event1.io/?utm_medium=opensource&utm_source=capacitor-helpscout">
        <img src="https://brand.event1.io/wordmark/wm-white.svg" width="200px">
    </a>
</p>

## Acknowledgements

- Thanks [Help Scout](https://www.helpscout.com) for creating Beacon and its mobile SDKs
- This plugin is not affiliated with or endorsed by Help Scout
