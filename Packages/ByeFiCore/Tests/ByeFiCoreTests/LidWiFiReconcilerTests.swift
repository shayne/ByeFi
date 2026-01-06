import XCTest
@testable import ByeFiCore

final class LidWiFiReconcilerTests: XCTestCase {
    func testScenarioWithPowerChangesWhileClosed() {
        let settings = LidWiFiReconciler.Settings(
            enabled: true,
            ignoreWhenOnACPower: true,
            reactToPowerChangesWhileClosed: true
        )

        var action = LidWiFiReconciler.action(
            trigger: .startup,
            lidClosed: false,
            isOnACPower: false,
            settings: settings
        )
        XCTAssertEqual(action, .restore(clearSavedState: true))

        action = LidWiFiReconciler.action(
            trigger: .lidChange,
            lidClosed: true,
            isOnACPower: false,
            settings: settings
        )
        XCTAssertEqual(action, .forceOff)

        action = LidWiFiReconciler.action(
            trigger: .powerChange,
            lidClosed: true,
            isOnACPower: true,
            settings: settings
        )
        XCTAssertEqual(action, .restore(clearSavedState: false))

        action = LidWiFiReconciler.action(
            trigger: .powerChange,
            lidClosed: true,
            isOnACPower: false,
            settings: settings
        )
        XCTAssertEqual(action, .forceOff)

        action = LidWiFiReconciler.action(
            trigger: .lidChange,
            lidClosed: false,
            isOnACPower: false,
            settings: settings
        )
        XCTAssertEqual(action, .restore(clearSavedState: true))
    }

    func testPowerChangeIgnoredWhenDisabled() {
        let settings = LidWiFiReconciler.Settings(
            enabled: true,
            ignoreWhenOnACPower: true,
            reactToPowerChangesWhileClosed: false
        )

        let action = LidWiFiReconciler.action(
            trigger: .powerChange,
            lidClosed: true,
            isOnACPower: true,
            settings: settings
        )

        XCTAssertEqual(action, .none)
    }
}
