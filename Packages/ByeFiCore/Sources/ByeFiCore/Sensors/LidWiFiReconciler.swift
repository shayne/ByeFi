//
//  LidWiFiReconciler.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/6/26.
//

import Foundation

struct LidWiFiReconciler {
    struct Settings {
        let enabled: Bool
        let ignoreWhenOnACPower: Bool
        let reactToPowerChangesWhileClosed: Bool
    }

    enum Trigger {
        case lidChange
        case powerChange
        case settingsChange
        case startup
    }

    enum Action: Equatable {
        case none
        case forceOff
        case restore(clearSavedState: Bool)
    }

    static func action(
        trigger: Trigger,
        lidClosed: Bool?,
        isOnACPower: Bool,
        settings: Settings
    ) -> Action {
        guard settings.enabled else {
            return .restore(clearSavedState: true)
        }

        guard let lidClosed else {
            return .none
        }

        if trigger == .powerChange && lidClosed && !settings.reactToPowerChangesWhileClosed {
            return .none
        }

        if settings.ignoreWhenOnACPower && isOnACPower {
            return .restore(clearSavedState: false)
        }

        return lidClosed ? .forceOff : .restore(clearSavedState: true)
    }
}
