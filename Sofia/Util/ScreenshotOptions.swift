import Foundation
import SofiaCore

/// Vue à afficher au lancement pour les captures d'écran de l'App Store, passée en arguments de
/// lancement par .github/scripts/screenshots.sh, par exemple :
/// `-SofiaScreenshotTab remit -SofiaScreenshotDetail YES`,
/// `-SofiaScreenshotTab stats -SofiaScreenshotStatsPeriod ALL -SofiaScreenshotStatsSection curve`.
/// Sans ces arguments (lancement normal), l'app démarre comme d'habitude.
enum ScreenshotOptions {
    /// Les arguments `-clé valeur` arrivent dans le domaine des arguments des UserDefaults.
    private static var defaults: UserDefaults { .standard }

    /// Onglet ouvert : « graph » (par défaut), « remit », « stats » ou « settings ».
    static var tab: String? {
        defaults.string(forKey: "SofiaScreenshotTab")
    }

    /// Ouvre le détail de la première alerte dès qu'elles sont chargées.
    static var opensFirstAlert: Bool {
        defaults.bool(forKey: "SofiaScreenshotDetail")
    }

    /// Ouvre l'avis REMIT complet de la première unité de la première alerte (par-dessus son détail).
    static var opensFirstNotice: Bool {
        defaults.bool(forKey: "SofiaScreenshotNotice")
    }

    /// Ouvre la feuille « À propos ».
    static var showsAbout: Bool {
        defaults.bool(forKey: "SofiaScreenshotAbout")
    }

    /// Période des statistiques, par sa valeur brute (`DAY`, `WEEK`, `MONTH`, `ALL`).
    static var statsPeriod: StatsPeriod? {
        defaults.string(forKey: "SofiaScreenshotStatsPeriod").flatMap(StatsPeriod.init(rawValue:))
    }

    /// Carte des statistiques amenée en haut de l'écran : `records`, `curve`, `units` ou `gb`.
    static var statsSection: String? {
        defaults.string(forKey: "SofiaScreenshotStatsSection")
    }

    /// Parcours automatique de l'app pour la vidéo de démonstration (.github/scripts/demo-video.sh).
    static var playsDemoTour: Bool {
        defaults.bool(forKey: "SofiaDemoTour")
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
