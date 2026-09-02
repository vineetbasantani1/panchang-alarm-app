import XCTest

/// These tests drive the actual compiled app in the Simulator via real taps,
/// the same way a person would. They run for free on GitHub's macOS Actions
/// runner (public repo). This is the closest thing to "someone tapped
/// through it" verification available without a Mac in hand.
final class PanchangAlarmUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSelectingATithiPresetUpdatesTheSummary() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Panchang Alarm"].waitForExistence(timeout: 10),
                       "Main screen should appear on launch")

        XCTAssertTrue(app.staticTexts["None"].waitForExistence(timeout: 5),
                       "Tithi summary should read 'None' before any selection")

        app.buttons["tithiRow"].tap()
        XCTAssertTrue(app.navigationBars["Choose Tithis"].waitForExistence(timeout: 5),
                       "Tapping the tithi row should open the tithi picker")

        // Tap the Ekadashi preset (covers tithi numbers 11 and 26).
        app.buttons["preset_Ekadashi"].tap()
        XCTAssertTrue(app.images["preset_Ekadashi_checked"].waitForExistence(timeout: 5),
                       "A checkmark should appear after tapping the Ekadashi preset")

        // Attach a screenshot here so it's visible even though this is a
        // headless CI run — proof the selection actually rendered correctly.
        attachScreenshot(named: "tithi-preset-selected")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Panchang Alarm"].waitForExistence(timeout: 5),
                       "Done should return to the main screen")

        XCTAssertTrue(app.staticTexts["2 selected"].waitForExistence(timeout: 5),
                       "Summary should now read '2 selected' after picking Ekadashi (11 + 26)")

        attachScreenshot(named: "main-screen-after-selection")
    }

    func testLocationPickerOpensAndCancels() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Not set"].waitForExistence(timeout: 10),
                       "Location summary should read 'Not set' initially")

        app.buttons["locationRow"].tap()
        // Longer timeout here than other navigation checks: this sheet
        // initializes MKLocalSearchCompleter, which has real setup overhead
        // (confirmed by CI logs — the tithi picker opened in ~1.7s with no
        // MapKit involved, while this one exceeded a 5s timeout).
        XCTAssertTrue(app.navigationBars["Choose Location"].waitForExistence(timeout: 20),
                       "Tapping the location row should open the location picker")

        attachScreenshot(named: "location-picker-open")

        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Panchang Alarm"].waitForExistence(timeout: 5),
                       "Cancel should return to the main screen")
    }

    func testEnableAlarmsButtonDisabledUntilLocationAndTithisAreSet() throws {
        let app = XCUIApplication()
        app.launch()

        let enableButton = app.buttons["enableAlarmsButton"]
        XCTAssertTrue(enableButton.waitForExistence(timeout: 10))
        XCTAssertFalse(enableButton.isEnabled,
                        "Enable Alarms should stay disabled with no location or tithis selected")

        attachScreenshot(named: "enable-button-disabled-state")
    }

    // MARK: - Helper

    private func attachScreenshot(named name: String) {
        let screenshot = XCUIApplication().screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
