//
//  SettingsView.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import Defaults
import SwiftUI
import AppKit

struct SettingsView: View {
    @Default(.lidControlEnabled) private var lidControlEnabled
    @Default(.ignoreWhenOnACPower) private var ignoreWhenOnACPower
    @Default(.reactToPowerChangesWhileClosed) private var reactToPowerChangesWhileClosed
    @Default(.hideMenuBar) private var hideMenuBar
    @Default(.launchAtLogin) private var launchAtLogin

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.10, blue: 0.12), Color(red: 0.16, green: 0.17, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 18) {
                header
                SettingsCard(title: "Behavior", subtitle: "Control Wi-Fi based on lid state.") {
                    SettingsToggleRow(
                        title: "Enable lid Wi-Fi control",
                        subtitle: "Toggle Wi-Fi off on close and restore on open.",
                        systemImage: "laptopcomputer",
                        isOn: $lidControlEnabled
                    )
                    SettingsToggleRow(
                        title: "Ignore when plugged into power",
                        subtitle: "Only react when running on battery.",
                        systemImage: "battery.100.bolt",
                        isOn: $ignoreWhenOnACPower
                    )
                    SettingsToggleRow(
                        title: "React to power changes while closed",
                        subtitle: "Restore or disable Wi-Fi if power changes while closed.",
                        systemImage: "bolt.circle",
                        isOn: $reactToPowerChangesWhileClosed
                    )
                }
                SettingsCard(title: "App", subtitle: "Startup and visibility options.") {
                    SettingsToggleRow(
                        title: "Open at login",
                        subtitle: "Start ByeFi automatically.",
                        systemImage: "arrow.clockwise.circle",
                        isOn: $launchAtLogin
                    )
                    .onChange(of: launchAtLogin) { _, newValue in
                        let currentState = LaunchAtLoginManager.isEnabled
                        if newValue != currentState {
                            LaunchAtLoginManager.setEnabled(newValue)
                        }
                        Defaults[.launchAtLoginConfigured] = true
                        launchAtLogin = LaunchAtLoginManager.isEnabled
                    }
                    SettingsToggleRow(
                        title: "Hide from menu bar",
                        subtitle: "Disable the status item and use Settings only.",
                        systemImage: "menubar.rectangle",
                        isOn: $hideMenuBar
                    )
                    SettingsLinkRow(
                        title: "Project site",
                        subtitle: "View ByeFi on GitHub.",
                        systemImage: "link"
                    ) {
                        NSWorkspace.shared.open(AppLinks.projectURL)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 520, idealHeight: 620)
        .onAppear {
            launchAtLogin = LaunchAtLoginManager.isEnabled
        }
    }

    @ViewBuilder
    private var header: some View {
        let accent = Color.accentColor
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.9), accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "wifi")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("ByeFi")
                    .font(.custom("Avenir Next", size: 26).weight(.semibold))
                    .foregroundStyle(Color.white)
                Text("Kill Wi-Fi when your lid is closed to save battery.")
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Avenir Next", size: 15).weight(.semibold))
                    .foregroundStyle(Color.white)
                Text(subtitle)
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Avenir Next", size: 13).weight(.semibold))
                    .foregroundStyle(Color.white)
                Text(subtitle)
                    .font(.custom("Avenir Next", size: 11))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.custom("Avenir Next", size: 13).weight(.semibold))
                        .foregroundStyle(Color.white)
                    Text(subtitle)
                        .font(.custom("Avenir Next", size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}
