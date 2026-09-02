# Panchang Alarm

Lets you pick any combination of Hindu lunar tithis (Ekadashi, Purnima,
Sankashti Chaturthi, or any of the full 30) and any location, then rings a
real system alarm (via AlarmKit, iOS 26+) on those days — falling back to a
time-sensitive notification if AlarmKit isn't available/approved yet.

## Honesty notes — read this first

This project was written without access to a Mac or Xcode, so parts of it
have different levels of confidence:

- **`TithiCalculator.swift` (the core astronomy) — verified.** The Sun/Moon
  position formulas were implemented in Python first and numerically checked
  against the Swiss Ephemeris (a high-precision astronomical library) across
  6 dates and 3 widely-spaced locations. Accuracy: tithi within 0.02-0.06°
  (well inside the 12° width of one tithi), sunrise within 1-3 minutes. This
  file was then mechanically translated to Swift — the math itself is solid.
- **SwiftUI views, models, location search — standard APIs, high confidence.**
  These use long-established, well-documented frameworks (SwiftUI, MapKit,
  UserNotifications) the way they're normally used.
- **`AlarmScheduler.swift`'s AlarmKit branch — draft, needs verification.**
  AlarmKit is a brand-new framework (introduced 2025) and I could only work
  from public documentation excerpts and a WWDC session transcript, not a
  live compiler. The exact method/type names in the AlarmKit section are a
  best-effort reconstruction and will very likely need small corrections
  once opened in real Xcode with autocomplete and current docs. The
  notification fallback path in the same file is standard and should work
  as written, so the app is functional even before the AlarmKit part is
  fixed up.

**First thing to do when you get into Xcode:** open `AlarmScheduler.swift`,
build the project, and fix any compiler errors in the AlarmKit section using
Xcode's autocomplete and the current AlarmKit docs
(https://developer.apple.com/documentation/AlarmKit) as ground truth.

## Project structure

```
PanchangAlarm/
  Package.swift                          <- SPM app definition, open this in Xcode
  Sources/PanchangAlarm/
    TithiCalculator.swift                <- verified astronomy
    TithiModels.swift                    <- tithi list + presets + saved config
    AlarmScheduler.swift                 <- AlarmKit (draft) + notification fallback
    LocationSearchService.swift          <- MapKit place search
    TithiPickerView.swift                <- tithi selection screen
    LocationPickerView.swift             <- location search screen
    ContentView.swift                    <- main screen
    PanchangAlarmApp.swift               <- @main entry point
  Tests/PanchangAlarmTests/
    TithiCalculatorTests.swift           <- unit tests against verified reference dates
  .github/workflows/build-and-test.yml   <- free CI build+test on GitHub's macOS runner
```

## Testing on the Simulator — two paths

### Path A: Free, automated, no Mac needed (verification, not hands-on)

1. Create a **public** GitHub repository (must be public — macOS Actions
   runners are free and unlimited on public repos, but cost money on
   private ones) and push all these files to it, preserving the folder
   structure exactly (especially `.github/workflows/build-and-test.yml`).
2. Go to the repo's **Actions** tab. The "Build and Test (iOS Simulator)"
   workflow should appear and run automatically on push, or trigger it
   manually via "Run workflow".
3. Once it finishes, check the log for build/test pass or fail, and
   download the **simulator-screenshots** artifact from the run's summary
   page to see an actual screenshot of the app running in the Simulator.

This confirms the app compiles and its logic works, entirely free, with no
Mac — but you're watching a recording, not interacting with it live.

### Path B: Real, hands-on testing (costs a little, needs a rented Mac)

1. Rent a cloud Mac session (e.g. MacinCloud pay-as-you-go, ~$1/hour).
2. Open `Package.swift` directly in Xcode (File > Open, select the file —
   Xcode will treat the whole folder as the project, no `.xcodeproj`
   needed).
3. Pick an iPhone Simulator from the device dropdown, hit the Run button
   (▶). The Simulator boots and you can tap around the app for real.
4. This is also where you'll fix any AlarmKit compiler errors (see
   "Honesty notes" above) using Xcode's live error messages and
   autocomplete.

## Publishing to the App Store — full steps

1. **Enroll in the Apple Developer Program** ($99/year) at
   developer.apple.com using your Apple ID.
2. **Get access to Xcode** — either rent a cloud Mac session (MacinCloud
   etc.) or use a friend's Mac.
3. **Open `Package.swift` in Xcode**, set your Team under the project's
   Signing & Capabilities (this replaces the `teamIdentifier: nil` in
   `Package.swift`).
4. **Add required Info.plist keys** via the target's "Info" tab in Xcode:
   - `NSAlarmKitUsageDescription` — a short string explaining why the app
     needs to schedule alarms (e.g. "Used to ring an alarm on your chosen
     fasting days.")
5. **Fix the AlarmKit code** in `AlarmScheduler.swift` using Xcode's
   compiler errors and autocomplete as ground truth (see "Honesty notes").
6. **Request AlarmKit entitlement access** as early as possible (in
   parallel with development, not after finishing) via the Developer
   Portal — Certificates, Identifiers & Profiles → your App ID →
   Capabilities. Turnaround is unpredictable (days to months based on
   similar restricted-entitlement requests); the app works fine with the
   notification fallback while you wait.
7. **Add an app icon** — create a 1024x1024 image and add it via Xcode's
   Asset Catalog (Package.swift currently has `appIcon: nil`).
8. **Test on a real device** at least once before submitting — AlarmKit's
   silent-mode-breaking behavior can't be fully verified in the Simulator.
9. **Create the app listing in App Store Connect** (appstoreconnect.apple.com):
   screenshots (can be generated from the Simulator), description, privacy
   policy URL (required, since the app handles location data — even a
   simple one-page policy stating you don't collect/transmit personal data
   is enough if that's true of your implementation), and category.
10. **Archive and upload** the build from Xcode (Product → Archive →
    Distribute App → App Store Connect).
11. **Submit for review.** Apple's review typically takes 1-3 days;
    AlarmKit approval (step 6) is separate and may still be pending —
    that's fine, the app will just use the notification fallback until
    it comes through, then you can push an update.

## Customizing

- **Change the max scheduling window**: `maxDaysAhead` parameter in
  `AlarmScheduler.rescheduleAll`, currently 180 days.
- **Add more presets**: edit `TithiPreset.common` in `TithiModels.swift`.
- **Change bundle identifier**: edit `bundleIdentifier` in `Package.swift`
  before your first App Store submission (can't easily change later).
