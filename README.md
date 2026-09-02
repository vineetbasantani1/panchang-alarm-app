# Panchang Alarm

Lets you pick any combination of Hindu lunar tithis (Ekadashi, Purnima,
Sankashti Chaturthi, or any of the full 30) and any location, then rings a
real system alarm (via AlarmKit, iOS 26+) on those days — falling back to a
time-sensitive notification if AlarmKit isn't available/approved yet.

## What changed (read this first)

The first version of this project tried to define the whole iOS app inside
`Package.swift` using an experimental SwiftPM product type called
`.iOSApplication`, specifically to avoid hand-writing a `.xcodeproj` file
(which I can't reliably generate without a compiler to check my work
against). **That approach failed in real CI testing** — the error was
`type 'Product' has no member 'iOSApplication'`, meaning that product type
isn't supported by the toolchain actually used to build this. I was wrong
to rely on it without verifying it first.

This version is split into two honest pieces instead:

1. **`Sources/PanchangAlarmCore/`** — a plain, ordinary Swift library
   containing the tithi astronomy calculations and data models. No SwiftUI,
   no AlarmKit, nothing experimental. Builds with a completely standard
   `swift build` / `swift test`, verified by the included CI workflow.
2. **`AppSources/`** — the SwiftUI views and AlarmKit integration. These are
   NOT part of the buildable package. Instead, you'll create a normal iOS
   App project using Xcode's own "New Project" wizard (which reliably
   generates a correct project file, since it's Apple's own tooling doing
   it, not me guessing at the file format) and add these files to it. This
   is the standard, well-trodden way people build iOS apps — I was trying
   to skip it to make things more automated, and that shortcut broke.

## Honesty notes on code confidence

- **`TithiCalculator.swift` (the core astronomy) — verified.** Implemented
  in Python first, numerically checked against the Swiss Ephemeris across
  6 dates and 3 widely-spaced locations (Halifax, New Delhi, Sydney).
  Accuracy: tithi within 0.02-0.06° (well inside the 12° width of one
  tithi), sunrise within 1-3 minutes. Then mechanically translated to
  Swift. This is the one piece of the whole project I have real numeric
  confidence in.
- **`Package.swift` (corrected version) — high confidence, not compiler-verified.**
  Uses only `.library`, `.target`, `.testTarget` — extremely standard,
  long-stable SwiftPM APIs. I could not get an actual Swift compiler
  running in my own environment to confirm this, so "high confidence" here
  means "very standard, common pattern," not "I tested it." The CI run is
  the real test.
- **SwiftUI views, MapKit location search — standard APIs, similarly not
  compiler-verified but low-risk**, since they use ordinary, well-documented
  framework calls the way they're normally used.
- **`AlarmScheduler.swift`'s AlarmKit branch — still a draft.** AlarmKit is
  new enough that I only had public documentation excerpts to work from,
  not a live compiler. Expect to fix compiler errors here once you're in
  real Xcode. The notification fallback in the same file uses the
  long-established `UNUserNotificationCenter` API and should work as
  written.

## Project structure

```
PanchangAlarm/
  Package.swift                              <- plain library, builds via `swift build`/`swift test`
  Sources/PanchangAlarmCore/
    TithiCalculator.swift                    <- verified astronomy
    TithiModels.swift                        <- tithi list + presets + saved config
  Tests/PanchangAlarmCoreTests/
    TithiCalculatorTests.swift               <- unit tests against verified reference dates
  AppSources/                                <- NOT part of the package; add to a new Xcode App project
    AlarmScheduler.swift                     <- AlarmKit (draft) + notification fallback
    LocationSearchService.swift              <- MapKit place search
    TithiPickerView.swift                    <- tithi selection screen
    LocationPickerView.swift                 <- location search screen
    ContentView.swift                        <- main screen
    PanchangAlarmApp.swift                   <- @main entry point
  .github/workflows/build-and-test.yml       <- free CI: swift build + swift test on GitHub's macOS runner
```

## Testing the core library — free, no Mac needed

1. Push this to a **public** GitHub repository (public is what makes macOS
   Actions runners free and unlimited — private repos pay per-minute).
2. Go to the **Actions** tab. "Build and Test Core Library" runs
   automatically on push, or trigger it manually via "Run workflow".
3. Check the log: `swift build -v` should end without errors, and
   `swift test -v` should show all 3 tests passing (`testKnownTithiDates`,
   `testUpcomingMatchesFindsEkadashi`, `testTithiNamesCount`).

This only verifies the core calculation logic — it does not build or test
the actual app UI, since that now lives outside the package (see below).

## Assembling the full app in Xcode

Once you have Xcode access (rented cloud Mac or otherwise):

1. **File → New → Project → iOS → App.** Product Name: "PanchangAlarm",
   Interface: SwiftUI, Language: Swift. This generates a correct,
   working `.xcodeproj` — Apple's own tooling, not a hand-written file.
2. **Add the core library as a local package dependency**: File → Add
   Package Dependencies → Add Local... → select this repo's folder
   (the one containing `Package.swift`). This links `PanchangAlarmCore`
   into your new app project.
3. **Drag all files from `AppSources/`** into your new Xcode project's
   file navigator (check "Copy items if needed").
4. **Delete the default `ContentView.swift`** Xcode generated for you, so
   it doesn't conflict with the one you just added.
5. Build (⌘B) and fix whatever compiler errors come up — the AlarmKit
   section in `AlarmScheduler.swift` is the most likely spot (see
   "Honesty notes" above).
6. Run (⌘R) on a Simulator to test interactively.

## Publishing to the App Store — full steps

1. **Enroll in the Apple Developer Program** ($99/year) at
   developer.apple.com using your Apple ID.
2. **Get access to Xcode** — rent a cloud Mac session (MacinCloud etc.) or
   use a friend's Mac — then follow "Assembling the full app in Xcode" above.
3. **Set your Team** under the project's Signing & Capabilities.
4. **Add required Info.plist keys** via the target's "Info" tab in Xcode:
   - `NSAlarmKitUsageDescription` — e.g. "Used to ring an alarm on your
     chosen fasting days."
5. **Fix the AlarmKit code** using Xcode's compiler errors and the current
   docs (https://developer.apple.com/documentation/AlarmKit) as ground truth.
6. **Request AlarmKit entitlement access** as early as possible, in
   parallel with development — Developer Portal → your App ID →
   Capabilities. Turnaround is unpredictable; the app works fine with the
   notification fallback while you wait.
7. **Add an app icon** — 1024x1024 image via Xcode's Asset Catalog.
8. **Test on a real device** at least once — AlarmKit's silent-mode-breaking
   behavior can't be fully verified in the Simulator.
9. **Create the app listing in App Store Connect**: screenshots, description,
   privacy policy URL (required — even a simple one-page policy is enough
   if you're not collecting/transmitting personal data), category.
10. **Archive and upload** (Product → Archive → Distribute App → App Store
    Connect).
11. **Submit for review** (typically 1-3 days). AlarmKit approval (step 6)
    is separate and can lag behind — the app just uses the notification
    fallback until it's granted, then you push an update.

## Customizing

- **Change the max scheduling window**: `maxDaysAhead` parameter in
  `AlarmScheduler.rescheduleAll`, currently 180 days.
- **Add more presets**: edit `TithiPreset.common` in `TithiModels.swift`.
