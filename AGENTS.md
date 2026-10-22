# AGENTS.md

Guidance for AI agents and contributors working in this repository.

## What this is

`capacitor-helpscout` is a Capacitor 8 plugin that wraps the Help Scout Beacon mobile SDKs (iOS `Beacon` 4.1, Android `com.helpscout:beacon` 7.0.2). It is unofficial. The JavaScript API is the same on both platforms, with a few documented differences (see the README).

## Layout

| Path | Purpose |
| --- | --- |
| `src/definitions.ts` | The public TypeScript API and its JSDoc. Source of truth for the API. |
| `src/web.ts` | Web implementation. Every method rejects as unimplemented because Beacon mobile has no web target. |
| `src/index.ts` | `registerPlugin('HelpScout', ...)` |
| `ios/Sources/HelpScoutPlugin/HelpScoutPlugin.swift` | Capacitor bridge: argument parsing, `pluginMethods` list, threading |
| `ios/Sources/HelpScoutPlugin/HelpScout.swift` | Beacon logic and state, and the `HSBeaconDelegate` |
| `ios/Sources/HelpScoutPlugin/HelpScoutSupport.swift` | Value types (`HelpScoutConfig`, `HelpScoutUser`, prefill), errors and helpers |
| `android/src/main/kotlin/io/event1/plugins/helpscout/HelpScoutPlugin.kt` | Capacitor bridge: `@PluginMethod`s, argument parsing, threading |
| `android/src/main/kotlin/io/event1/plugins/helpscout/HelpScout.kt` | Beacon logic and state |
| `example-app/` | Manual test app. Not published to npm. |
| `Package.swift`, `CapacitorHelpscout.podspec`, `android/build.gradle` | Native dependency versions for the Beacon SDKs |

## Commands

```bash
npm run build          # clean, tsc, rollup
npm run lint           # eslint, prettier, swiftlint (needs `brew install swiftlint`)
npm run fmt            # autofix
npm run docs           # typedoc into out/
npm run verify:web     # build
npm run verify:android # cd android && ./gradlew clean build test
npm run verify:ios     # xcodebuild generic iOS build
```

iOS unit tests:

```bash
xcodebuild test -scheme CapacitorHelpscout -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation
```

Use Node 26 (pinned in `.tool-versions`, and used by every GitHub Actions job). Android needs JDK 21 and an Android SDK (`ANDROID_HOME`). Run `npm run build` and `npx cap sync` in `example-app/` to test in the example app.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org). [semantic-release](https://github.com/semantic-release/semantic-release) reads them to pick the next version and write release notes, so the format is not optional.

```
<type>(<optional scope>)<!>: <Subject>

<optional body>

<optional footer>
```

- Use an imperative subject starting with a capital letter and no trailing period, e.g. `feat: Add Secure Mode support to askQuestion`.
- Scope is optional. Use it for a single platform or area: `ios`, `android`, `web`, `example`, `ci`, `docs`.
- Mark breaking changes with `!` after the type (`feat!: Rename initialize options`) and/or a `BREAKING CHANGE:` footer explaining the migration.

| Type | Release |
| --- | --- |
| `feat` | minor |
| `fix`, `perf` | patch |
| any type with `!` or a `BREAKING CHANGE:` footer | major |
| `docs`, `chore`, `refactor`, `test`, `ci`, `build`, `style` | no release |

Changing the wrapped Beacon SDK version is a `feat` (or `feat!` if it raises minimum OS versions or breaks behavior). A pure dependency bump is a `chore`.

### Branches and releases

Releases are automated by `.github/workflows/release.yml`. A push to `next` publishes a stable release and a push to `beta` publishes a prerelease on the `beta` channel. Do not run `npm publish` by hand, and do not edit `version` in `package.json`.

## Adding or changing an API method

Keep both platforms and the docs in sync. A change is not done until all of these agree:

1. `src/definitions.ts`: signature and JSDoc, including which platform-specific behavior applies.
2. `src/web.ts`: add the method (it rejects as unimplemented).
3. iOS: add a `CAPPluginMethod` entry to `pluginMethods` and a matching `@objc func` in `HelpScoutPlugin.swift`, with the logic in `HelpScout.swift`.
4. Android: add a `@PluginMethod` in `HelpScoutPlugin.kt`, with the logic in `HelpScout.kt`.
5. `README.md`: the API table, and the platform differences table if behavior differs.
6. Tests for any logic that can be tested without a Beacon account.

If a Beacon feature exists on only one platform, still expose it, resolve as a no-op on the other platform, and say so in the JSDoc and README.

## Gotchas learned the hard way

- **Never name a plugin method `init`.** On iOS it collides with the `NSObject` initializer selector, which is why the method is `initialize`.
- **Do not use `HSBeacon.dismiss` on iOS.** In Beacon 4.1.0 it never returns on the main thread and never calls its completion. `close()` dismisses the presented view controller instead and emits `beaconClosed` itself if Beacon did not.
- **Run anything that touches Beacon's WebView on the Android UI thread.** `Beacon.clear()` crashed off the main thread. Use `runOnUi` in `HelpScoutPlugin.kt` for opening, `close`, `logout`, `reset`, `clear` and push handling.
- **Swift names differ from the Objective-C headers.** For example `openBeacon:` imports as `HSBeacon.open(_:)`, and `addAttributeWithKey:value:` as `addAttribute(withKey:value:)`. Let the compiler guide you.
- **Android manifest conflict.** Beacon sets `android:supportsRtl="false"`, so host apps need `tools:replace="android:supportsRtl"`. A library cannot fix this for the app. The README documents it.
- **Android `BeaconConfigOverrides`** is applied as one object. `HelpScout.kt` remembers every field, so a partial `configure()` call does not reset earlier values.
- **Rapid close then reopen on Android** can crash inside Beacon's own fragment code. Leave time between presentations when testing.
- **iOS Beacon needs Xcode 26+** and iOS 15+.

## Testing

Unit tests cover only logic that does not need a live Beacon: hex and color parsing, session attribute limits, screen mapping and the not-initialized guard. Anything that presents Beacon needs a real Beacon ID and must be checked by running `example-app` on a simulator or emulator.

Never commit a real Beacon ID, Secure Mode signature, or push token. The example app takes the Beacon ID from an input field.

## Style

- TypeScript is formatted with the Ionic Prettier config (`npm run fmt`). Swift follows the Ionic SwiftLint config. Kotlin follows the style of the surrounding files.
- Keep JSDoc complete: it is the source for the published typedoc site.
- Match the surrounding code's comment density. Comment the why, mostly for SDK workarounds.
