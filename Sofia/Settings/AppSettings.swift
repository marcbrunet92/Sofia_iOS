import Foundation
import Observation
import SwiftUI
import SofiaCore

/// Apparence de l'app : celle du système, ou forcée en clair / sombre.
enum AppAppearance: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var labelKey: String {
        switch self {
        case .system: return "settings_appearance_system"
        case .light: return "settings_appearance_light"
        case .dark: return "settings_appearance_dark"
        }
    }
}

/// Préférences de l'utilisateur, conservées dans UserDefaults et observées par les écrans.
@Observable
final class AppSettings {
    private enum Keys {
        static let windUnit = "settings.windUnit"
        static let appearance = "settings.appearance"
        static let defaultWindow = "settings.defaultWindow"
        static let outageReminders = "settings.outageReminders"
    }

    /// Unité de la vitesse du vent sur le graphique et dans les statistiques.
    private(set) var windUnit: WindSpeedUnit = .metersPerSecond
    private(set) var appearance: AppAppearance = .system
    /// Période affichée par le graphique à l'ouverture de l'app.
    private(set) var defaultWindow: TimeWindow = .month1
    /// Notifications au début et à la fin des indisponibilités annoncées.
    private(set) var outageReminders = false

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: Keys.windUnit), let unit = WindSpeedUnit(rawValue: stored) {
            windUnit = unit
        }
        if let stored = defaults.string(forKey: Keys.appearance), let value = AppAppearance(rawValue: stored) {
            appearance = value
        }
        if let stored = defaults.string(forKey: Keys.defaultWindow), let window = TimeWindow(rawValue: stored) {
            defaultWindow = window
        }
        outageReminders = defaults.bool(forKey: Keys.outageReminders)
    }

    func setWindUnit(_ unit: WindSpeedUnit) {
        windUnit = unit
        defaults.set(unit.rawValue, forKey: Keys.windUnit)
    }

    func setAppearance(_ value: AppAppearance) {
        appearance = value
        defaults.set(value.rawValue, forKey: Keys.appearance)
    }

    func setDefaultWindow(_ window: TimeWindow) {
        defaultWindow = window
        defaults.set(window.rawValue, forKey: Keys.defaultWindow)
    }

    func setOutageReminders(_ enabled: Bool) {
        outageReminders = enabled
        defaults.set(enabled, forKey: Keys.outageReminders)
    }
}
