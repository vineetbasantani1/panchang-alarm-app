import Foundation

/// A single selectable tithi (1...30) with its display name and paksha (fortnight).
public struct TithiOption: Identifiable, Hashable {
    public let number: Int // 1...30
    public var id: Int { number }
    public var name: String { TithiCalculator.tithiNames[number - 1] }
    public var paksha: String { number <= 15 ? "Shukla Paksha" : "Krishna Paksha" }
    public var displayName: String { "\(name) (\(paksha))" }

    public init(number: Int) {
        self.number = number
    }

    public static let all: [TithiOption] = (1...30).map { TithiOption(number: $0) }
}

/// A commonly-observed named group, which may span multiple tithi numbers
/// (e.g. "Ekadashi" covers both the Shukla and Krishna occurrences).
public struct TithiPreset: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let tithiNumbers: [Int]

    public init(title: String, subtitle: String, tithiNumbers: [Int]) {
        self.title = title
        self.subtitle = subtitle
        self.tithiNumbers = tithiNumbers
    }

    public static let common: [TithiPreset] = [
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
public struct AppAlarmConfig: Codable, Equatable {
    public var trackedTithiNumbers: Set<Int>
    public var latitude: Double
    public var longitude: Double
    public var locationName: String
    public var alarmHour: Int   // 0-23, local time
    public var alarmMinute: Int // 0-59

    public init(
        trackedTithiNumbers: Set<Int>,
        latitude: Double,
        longitude: Double,
        locationName: String,
        alarmHour: Int,
        alarmMinute: Int
    ) {
        self.trackedTithiNumbers = trackedTithiNumbers
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.alarmHour = alarmHour
        self.alarmMinute = alarmMinute
    }

    public static let empty = AppAlarmConfig(
        trackedTithiNumbers: [],
        latitude: 0,
        longitude: 0,
        locationName: "",
        alarmHour: 6,
        alarmMinute: 0
    )
}
