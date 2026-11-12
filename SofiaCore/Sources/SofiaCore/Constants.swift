import Foundation

/// Équivalent de Constants.kt (Android).
public enum SofiaConstants {
    public static let baseURL = "https://sofia.lemarc.fr/"
    public static let maxCapacityMw: Double = 1400.0
    public static let bmus = ["T_SOFOW-11", "T_SOFOW-12", "T_SOFOW-21", "T_SOFOW-22"]
    /// 2026-04-01T00:00:00Z
    public static let historyStart = Date(timeIntervalSince1970: 1_775_001_600)

    /// App Group optionnel : s'il est activé sur l'app ET le widget, ils partagent le cache.
    public static let appGroupIdentifier = "group.com.lemarc.Sofia"

    /// Capacité installée de chaque unité, en MW (capacité normale des avis REMIT) ; leur somme
    /// vaut `maxCapacityMw`.
    public static let unitCapacitiesMw: [String: Double] = [
        "T_SOFOW-11": 336,
        "T_SOFOW-12": 350,
        "T_SOFOW-21": 406,
        "T_SOFOW-22": 308,
    ]

    /// Consommation électrique annuelle d'un foyer britannique type (valeur médiane Ofgem), en MWh.
    public static let homeAnnualMwh = 2.7

    /// Version web de l'app.
    public static let webURL = "https://sofia.lemarc.fr/"
}

/// Unité d'affichage de la vitesse du vent. L'API la donne en km/h.
public enum WindSpeedUnit: String, CaseIterable, Codable, Sendable {
    case metersPerSecond = "ms"
    case kilometersPerHour = "kmh"
    case knots = "kn"

    public var symbol: String {
        switch self {
        case .metersPerSecond: return "m/s"
        case .kilometersPerHour: return "km/h"
        case .knots: return "kn"
        }
    }

    public func fromKmh(_ value: Double) -> Double {
        switch self {
        case .metersPerSecond: return value / 3.6
        case .kilometersPerHour: return value
        case .knots: return value / 1.852
        }
    }
}

public enum TimeWindow: String, CaseIterable, Codable, Sendable {
    case hours24 = "HOURS_24"
    case days7 = "DAYS_7"
    case month1 = "MONTH_1"
    case month6 = "MONTH_6"
    case all = "ALL"

    /// Durée de la fenêtre en secondes ; `nil` pour « All ».
    public var duration: TimeInterval? {
        switch self {
        case .hours24: return 24 * 3_600
        case .days7: return 7 * 86_400
        case .month1: return 30 * 86_400
        case .month6: return 6 * 30 * 86_400
        case .all: return nil
        }
    }

    /// Libellé court des chips (clé de localisation).
    public var labelKey: String {
        switch self {
        case .hours24: return "time_window_24h"
        case .days7: return "time_window_7d"
        case .month1: return "time_window_1m"
        case .month6: return "time_window_short_6m"
        case .all: return "time_window_all"
        }
    }

    /// Libellé long (configuration du widget graphique).
    public var longLabelKey: String {
        switch self {
        case .hours24: return "time_window_long_24h"
        case .days7: return "time_window_long_7d"
        case .month1: return "time_window_long_1m"
        case .month6: return "time_window_long_6m"
        case .all: return "time_window_long_all"
        }
    }

    /// Titre en capitales du widget graphique.
    public var shortTitleKey: String {
        switch self {
        case .hours24: return "time_window_short_24h"
        case .days7: return "time_window_short_7d"
        case .month1: return "time_window_short_1m"
        case .month6: return "time_window_short_6m"
        case .all: return "time_window_short_all"
        }
    }

    /// Les données réelles (B1610) ne sont affichées qu'à partir de 7 jours (« All » inclus).
    public var showsActual: Bool {
        guard let duration else { return true }
        return duration >= 7 * 86_400
    }
}
