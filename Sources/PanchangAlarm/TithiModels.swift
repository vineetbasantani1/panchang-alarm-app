import Foundation

/// A single selectable tithi (1...30) with its display name and paksha (fortnight).
struct TithiOption: Identifiable, Hashable {
    let number: Int // 1...30
    var id: Int { number }
    var name: String { TithiCalculator.tithiNames[number - 1] }
    var paksha: String { number <= 15 ? "Shukla Paksha" : "Krishna Paksha" }
    var displayName: String { "\(name) (\(paksha))" }

    static let all: [TithiOption] = (1...30).map { TithiOption(number: $0) }
}

/// A commonly-observed named group, which may span multiple tithi numbers
/// (e.g. "Ekadashi" covers both the Shukla and Krishna occurrences).
struct TithiPreset: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tithiNumbers: [Int]

    static let common: [TithiPreset] = [
        TithiPreset(title: "Ekadashi", subtitle: "Both fortnights \u{2014} 11th day", tithiNumbers: [11, 26]),
        TithiPreset(title: "Purnima", subtitle: "Full moon", tithiNumbers: [15]),
        TithiPreset(title: "Amavasya", subtitle: "New moon", tithiNumbers: [30]),
        TithiPreset(title: "Sankashti Chaturthi", subtitle: "Krishna Paksha, 4th day", tithiNumbers: [19]),
        TithiPreset(title: "Pradosh", subtitle: "Both fortnights \u{2014} 13th day", tithiNumbers: [13, 28]),
    ]
}

/// The user's full saved configuration: which tithis to track, where, and when to ring.
/// NOTE: named "AppAlarmConfig" (not "AlarmConfiguration") to avoid colliding
/// with AlarmKit's own `AlarmConfiguration` type once that framework is imported.
struct AppAlarmConfig: Codable, Equatable {
    var trackedTithiNumbers: Set<Int>
    var latitude: Double
    var longitude: Double
    var locationName: String
    var alarmHour: Int   // 0-23, local time
    var alarmMinute: Int // 0-59

    static let empty = AppAlarmConfig(
        trackedTithiNumbers: [],
        latitude: 0,
        longitude: 0,
        locationName: "",
        alarmHour: 6,
        alarmMinute: 0
    )
}
