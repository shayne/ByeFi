//
//  PowerSourceMonitor.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import Foundation
import IOKit.ps

enum PowerSourceMonitor {
    static func isOnACPower() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return true
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                  let state = description[kIOPSPowerSourceStateKey as String] as? String else {
                continue
            }
            return state != kIOPSBatteryPowerValue
        }

        return true
    }
}

final class PowerSourceObserver {
    private var runLoopSource: CFRunLoopSource?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() {
        guard runLoopSource == nil else { return }
        let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let observer = Unmanaged<PowerSourceObserver>.fromOpaque(context).takeUnretainedValue()
            observer.handler()
        }, Unmanaged.passUnretained(self).toOpaque())
        guard let source else { return }
        let runLoopSource = source.takeRetainedValue()
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
    }

    deinit {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
    }
}
