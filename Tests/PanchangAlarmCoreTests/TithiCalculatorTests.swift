import XCTest
@testable import PanchangAlarmCore

final class TithiCalculatorTests: XCTestCase {

    // Halifax, NS coordinates used throughout the project.
    let latitude = 44.6488
    let longitude = -63.5752

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    /// These expected values were independently verified against the Swiss
    /// Ephemeris (pyswisseph) for Halifax sunrise times in a Python sandbox
    /// before this Swift port was written. See TithiCalculator.swift header.
    func testKnownTithiDates() {
        let cases: [(Int, Int, Int, Int, String)] = [
            (2026, 8, 19, 7, "Saptami"),
            (2026, 8, 23, 11, "Ekadashi"),
            (2026, 8, 27, 15, "Purnima"),
            (2026, 8, 31, 19, "Chaturthi"),
            (2026, 9, 7, 26, "Ekadashi"),
            (2026, 10, 25, 15, "Purnima"),
        ]

        for (y, m, d, expectedNumber, expectedName) in cases {
            let result = TithiCalculator.tithi(onDate: date(y, m, d), latitude: latitude, longitude: longitude)
            XCTAssertEqual(result.number, expectedNumber, "\(y)-\(m)-\(d): expected tithi \(expectedNumber), got \(result.number)")
            XCTAssertEqual(result.name, expectedName, "\(y)-\(m)-\(d): expected \(expectedName), got \(result.name)")
        }
    }

    func testUpcomingMatchesFindsEkadashi() {
        let matches = TithiCalculator.upcomingMatches(
            trackedTithis: [11, 26],
            startDate: date(2026, 8, 19),
            maxDays: 45,
            latitude: latitude,
            longitude: longitude
        )
        // We expect at least the two Ekadashis found manually earlier: Aug 23 and Sep 7.
        XCTAssertGreaterThanOrEqual(matches.count, 2)
        XCTAssertTrue(matches.contains { Calendar.current.isDate($0.date, inSameDayAs: date(2026, 8, 23)) })
        XCTAssertTrue(matches.contains { Calendar.current.isDate($0.date, inSameDayAs: date(2026, 9, 7)) })
    }

    func testTithiNamesCount() {
        XCTAssertEqual(TithiCalculator.tithiNames.count, 30)
    }
}
