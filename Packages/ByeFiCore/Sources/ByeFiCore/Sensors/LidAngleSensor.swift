//
//  LidAngleSensor.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import CoreWLAN
import Defaults
import Foundation
import IOKit.hid
import os

final class LidAngleSensor {
    private var hidDevice: IOHIDDevice?

    private enum HID {
        static let sensorPage = Int(kHIDPage_Sensor)
        static let deviceOrientation = Int(kHIDUsage_Snsr_Orientation_DeviceOrientation)
        static let tiltXAxis = Int(kHIDUsage_Snsr_Data_Orientation_TiltXAxis)
    }

    init() {
        hidDevice = findLidAngleSensor()
        if let device = hidDevice {
            IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    deinit {
        stopLidAngleUpdates()
    }

    var isAvailable: Bool {
        hidDevice != nil
    }

    func lidAngle() -> Double? {
        guard let device = hidDevice else {
            return nil
        }

        if let element = findAngleElement(for: device) {
            var valueRef: Unmanaged<IOHIDValue>?
            let result = withUnsafeMutablePointer(to: &valueRef) { pointer -> IOReturn in
                pointer.withMemoryRebound(to: Unmanaged<IOHIDValue>.self, capacity: 1) { rebound in
                    IOHIDDeviceGetValue(device, element, rebound)
                }
            }
            if result == kIOReturnSuccess, let valueRef {
                let value = valueRef.takeUnretainedValue()
                return Double(IOHIDValueGetIntegerValue(value))
            }
        }

        return nil
    }

    func startLidAngleUpdates() {
        if hidDevice == nil {
            hidDevice = findLidAngleSensor()
        }

        if let device = hidDevice {
            IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    func stopLidAngleUpdates() {
        if let device = hidDevice {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            hidDevice = nil
        }
    }

    private func findLidAngleSensor() -> IOHIDDevice? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            return nil
        }
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }

        let matching: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDDeviceUsagePageKey: HID.sensorPage,
            kIOHIDDeviceUsageKey: HID.deviceOrientation,
        ]

        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        guard let devices = IOHIDManagerCopyDevices(manager) else {
            return nil
        }

        let count = CFSetGetCount(devices)
        guard count > 0 else {
            return nil
        }

        var deviceArray = [UnsafeRawPointer?](repeating: nil, count: count)
        CFSetGetValues(devices, &deviceArray)

        for index in 0..<count {
            guard let rawDevice = deviceArray[index] else { continue }
            let device = Unmanaged<IOHIDDevice>.fromOpaque(rawDevice).takeUnretainedValue()

            guard IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
                continue
            }

            let element = findAngleElement(for: device)
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            if element != nil {
                return device
            }
        }

        return nil
    }

    private func findAngleElement(for device: IOHIDDevice) -> IOHIDElement? {
        let matching: [String: Any] = [
            kIOHIDElementUsagePageKey: HID.sensorPage,
            kIOHIDElementUsageKey: HID.tiltXAxis,
        ]

        guard let elements = IOHIDDeviceCopyMatchingElements(
            device,
            matching as CFDictionary,
            IOOptionBits(kIOHIDOptionsTypeNone)
        ) else {
            return nil
        }

        let count = CFArrayGetCount(elements)
        guard count > 0 else {
            return nil
        }

        guard let rawElement = CFArrayGetValueAtIndex(elements, 0) else {
            return nil
        }
        let element = Unmanaged<IOHIDElement>.fromOpaque(rawElement).takeUnretainedValue()
        return element
    }
}

@MainActor
final class LidAngleMonitor: ObservableObject {
    @Published var angle: Double?

    private let sensor = LidAngleSensor()
    private let wifiController = WiFiController()
    private var task: Task<Void, Never>?
    private let logger = Logger(subsystem: "ByeFi", category: "LidAngle")
    private let pollInterval = Duration.seconds(1)
    private let lidClosedThreshold = 359.0
    private let lidClosedNearZeroThreshold = 1.0
    private var wasClosed: Bool?

    init() {
        start()
    }

    deinit {
        task?.cancel()
    }

    func start() {
        task?.cancel()
        task = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                self.pollAngle()
                try? await Task.sleep(for: pollInterval)
            }
        }
    }

    private func pollAngle() {
        let newAngle = sensor.lidAngle()
        angle = newAngle

        if let newAngle {
            let isClosed = newAngle >= lidClosedThreshold || newAngle <= lidClosedNearZeroThreshold
            if shouldControlWiFi() {
                if isClosed, wasClosed != true {
                    logger.info("lid closed")
                    wifiController.handleLidClosed()
                } else if !isClosed, wasClosed == true {
                    logger.info("lid opened")
                    wifiController.handleLidOpened()
                }
            }
            wasClosed = isClosed
        }
    }

    private func shouldControlWiFi() -> Bool {
        guard Defaults[.lidControlEnabled] else {
            return false
        }

        if Defaults[.ignoreWhenOnACPower] {
            return !PowerSourceMonitor.isOnACPower()
        }

        return true
    }
}

final class WiFiController {
    private let logger = Logger(subsystem: "ByeFi", category: "WiFi")
    private var lastKnownPowerState: Bool?

    func handleLidClosed() {
        guard let currentPower = currentPowerState() else {
            return
        }

        lastKnownPowerState = currentPower
        if currentPower {
            setPower(false)
        }
    }

    func handleLidOpened() {
        guard let previousPower = lastKnownPowerState else {
            return
        }

        setPower(previousPower)
        lastKnownPowerState = nil
    }

    private func setPower(_ enabled: Bool) {
        let client = CWWiFiClient.shared()
        guard let interface = client.interface() else {
            logger.error("No Wi-Fi interface found")
            return
        }

        do {
            try interface.setPower(enabled)
            logger.info("Wi-Fi power set to \(enabled ? "on" : "off")")
        } catch {
            logger.error("Failed to set Wi-Fi power: \(error.localizedDescription)")
        }
    }

    private func currentPowerState() -> Bool? {
        let client = CWWiFiClient.shared()
        guard let interface = client.interface() else {
            logger.error("No Wi-Fi interface found")
            return nil
        }

        return interface.powerOn()
    }
}
