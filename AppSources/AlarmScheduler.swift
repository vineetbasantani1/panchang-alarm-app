import Foundation
import UserNotifications
import PanchangAlarmCore
#if canImport(AlarmKit)
import AlarmKit
#endif

/// Schedules a real system alarm for each upcoming tracked-tithi date.
///
/// IMPORTANT HONESTY NOTE (read before relying on this file):
/// AlarmKit is a brand-new framework (iOS 26, mid-2025 onward) and its full
/// API surface isn't something I could verify against a compiler here since
/// this project was written without access to Xcode. The AlarmKit branch
/// below is a best-effort implementation based on publicly available WWDC
/// session notes and documentation excerpts, and its exact method names/
/// signatures (AlarmManager.schedule, AlarmConfiguration, AlarmAttributes,
/// etc.) should be treated as a draft to verify and adjust against Xcode's
/// live autocomplete and the current AlarmKit documentation once you're in
/// a real Xcode project. The Time-Sensitive Notification fallback path,
/// by contrast, uses the long-established UNUserNotificationCenter API and
/// should work as written.
@MainActor
final class AlarmScheduler: ObservableObject {

    @Published private(set) var lastError: String?
    @Published private(set) var usingRealAlarms: Bool = false

    /// Clears all previously scheduled app alarms/notifications, then
    /// schedules fresh ones for every upcoming matching tithi date.
    func rescheduleAll(config: AppAlarmConfig, maxDaysAhead: Int = 180) async {
        lastError = nil

        let matches = TithiCalculator.upcomingMatches(
            trackedTithis: config.trackedTithiNumbers,
            startDate: Date(),
            maxDays: maxDaysAhead,
            latitude: config.latitude,
            longitude: config.longitude
        )

        guard !matches.isEmpty else {
            lastError = "No matching tithi dates found in the next \(maxDaysAhead) days \u{2014} check your tithi selection."
            return
        }

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            let authorized = await requestAlarmKitAuthorization()
            if authorized {
                await scheduleWithAlarmKit(matches: matches, config: config)
                usingRealAlarms = true
                return
            }
        }
        #endif

        // Fallback: Time-Sensitive local notifications.
        await scheduleWithNotifications(matches: matches, config: config)
        usingRealAlarms = false
    }

    // MARK: - AlarmKit path (draft — verify against Xcode before shipping)

    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    private func requestAlarmKitAuthorization() async -> Bool {
        do {
            let manager = AlarmManager.shared
            switch manager.authorizationState {
            case .authorized:
                return true
            case .notDetermined:
                let state = try await manager.requestAuthorization()
                return state == .authorized
            default:
                return false
            }
        } catch {
            lastError = "AlarmKit authorization failed: \(error.localizedDescription)"
            return false
        }
    }

    @available(iOS 26.0, *)
    private func scheduleWithAlarmKit(
        matches: [(date: Date, tithiNumber: Int, tithiName: String)],
        config: AppAlarmConfig
    ) async {
        let manager = AlarmManager.shared
        // Clear previously scheduled alarms created by this app before re-adding.
        // NOTE: verify the correct AlarmKit API to enumerate/cancel this app's
        // existing alarms in Xcode — AlarmManager likely exposes `alarms` and
        // a `cancel(id:)` method; adjust as needed.

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        for match in matches {
            guard let fireDate = calendar.date(
                bySettingHour: config.alarmHour,
                minute: config.alarmMinute,
                second: 0,
                of: match.date
            ) else { continue }

            let label = "\(match.tithiName) today"

            do {
                // DRAFT API — the exact AlarmConfiguration/AlarmAttributes
                // initializer shape needs confirming in Xcode. This is
                // written to match the general shape described in Apple's
                // WWDC25 "Wake up to the AlarmKit API" session.
                let alarmID = UUID()
                let configuration = AlarmManager.AlarmConfiguration(
                    schedule: .fixed(fireDate),
                    label: label
                )
                try await manager.schedule(id: alarmID, configuration: configuration)
            } catch {
                lastError = "Failed to schedule alarm for \(match.date): \(error.localizedDescription)"
            }
        }
    }
    #endif

    // MARK: - Notification fallback (standard, well-established API)

    private func scheduleWithNotifications(
        matches: [(date: Date, tithiNumber: Int, tithiName: String)],
        config: AppAlarmConfig
    ) async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                lastError = "Notification permission was not granted."
                return
            }
        } catch {
            lastError = "Notification authorization failed: \(error.localizedDescription)"
            return
        }

        // Remove previously scheduled requests from this app before re-adding.
        center.removeAllPendingNotificationRequests()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        for match in matches {
            var triggerDate = calendar.dateComponents([.year, .month, .day], from: match.date)
            triggerDate.hour = config.alarmHour
            triggerDate.minute = config.alarmMinute

            let content = UNMutableNotificationContent()
            content.title = "Today is \(match.tithiName)"
            content.body = "\(config.locationName): today is \(match.tithiName)."
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(
                identifier: "panchang-\(match.date.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
            } catch {
                lastError = "Failed to schedule notification for \(match.date): \(error.localizedDescription)"
            }
        }
    }
}
