import Foundation
import SofiaCore

/// Vue à afficher au lancement pour les captures d'écran de l'App Store, passée en arguments de
/// lancement par .github/scripts/screenshots.sh, par exemple :
/// `-SofiaScreenshotTab remit -SofiaScreenshotDetail YES`.
/// Sans ces arguments (lancement normal), l'app démarre comme d'habitude.
enum ScreenshotOptions {
    /// Les arguments `-clé valeur` arrivent dans le domaine des arguments des UserDefaults.
    private static var defaults: UserDefaults { .standard }

    /// « graph » (par défaut) ou « remit ».
    static var opensAlertsTab: Bool {
        defaults.string(forKey: "SofiaScreenshotTab") == "remit"
    }

    /// Ouvre le détail de la première alerte dès qu'elles sont chargées.
    static var opensFirstAlert: Bool {
        defaults.bool(forKey: "SofiaScreenshotDetail")
    }

    /// Fenêtre de temps, par sa valeur brute (`HOURS_24`, `DAYS_7`, `MONTH_1`, `MONTH_6`, `ALL`).
    static var window: TimeWindow? {
        defaults.string(forKey: "SofiaScreenshotWindow").flatMap(TimeWindow.init(rawValue:))
    }

    /// Jeux de données séparés par des virgules : `pn`, `b1610`, `weather`, `mel`.
    static var datasets: [GraphDataset]? {
        guard let value = defaults.string(forKey: "SofiaScreenshotDatasets") else { return nil }
        let datasets = value.split(separator: ",").compactMap { GraphDataset(argument: String($0)) }
        return datasets.isEmpty ? nil : datasets
    }
}

extension GraphDataset {
    init?(argument: String) {
        switch argument.trimmingCharacters(in: .whitespaces).lowercased() {
        case "pn": self = .pn
        case "b1610": self = .b1610
        case "weather": self = .weather
        case "mel": self = .mel
        default: return nil
        }
    }
}
