import Combine
import Foundation
import SofiaCore

/// Équivalent de data/settings/SettingsRepository.kt : le mode test persistant, observable
/// par tous les view models (comme le Flow `testMode` du DataStore).
final class SettingsRepository {
    static let shared = SettingsRepository()

    private let subject: CurrentValueSubject<Bool, Never>

    init() {
        subject = CurrentValueSubject(SofiaSettings.testMode)
    }

    /// Émet immédiatement la valeur courante puis chaque changement.
    var testMode: AnyPublisher<Bool, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }

    func setTestMode(_ enabled: Bool) {
        SofiaSettings.setTestMode(enabled)
        subject.send(enabled)
    }
}
