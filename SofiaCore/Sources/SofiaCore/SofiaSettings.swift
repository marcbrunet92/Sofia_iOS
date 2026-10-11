import Foundation

/// Persistance du mode test, équivalent du DataStore `sofia_settings` de SettingsRepository.kt.
///
/// Utilise les UserDefaults de l'App Group quand il est disponible (réglage partagé avec le
/// widget), sinon les UserDefaults standard.
public enum SofiaSettings {
    public static var defaults: UserDefaults {
        let fileManager = FileManager.default
        if fileManager.containerURL(forSecurityApplicationGroupIdentifier: SofiaConstants.appGroupIdentifier) != nil,
           let shared = UserDefaults(suiteName: SofiaConstants.appGroupIdentifier) {
            return shared
        }
        return .standard
    }

    public static var testMode: Bool {
        defaults.bool(forKey: SofiaConstants.testModeKey)
    }

    public static func setTestMode(_ enabled: Bool) {
        defaults.set(enabled, forKey: SofiaConstants.testModeKey)
    }
}
