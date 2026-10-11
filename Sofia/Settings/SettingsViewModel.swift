import Combine
import Foundation
import Observation
import WidgetKit

struct SettingsUiState {
    var testMode = false
}

/// Équivalent de ui/settings/SettingsViewModel.kt.
@Observable
final class SettingsViewModel {
    private(set) var uiState = SettingsUiState()

    private let settingsRepository: SettingsRepository

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository

        settingsRepository.testMode
            .sink { [weak self] enabled in
                self?.uiState = SettingsUiState(testMode: enabled)
                // Les widgets affichent les données du mode courant
                WidgetCenter.shared.reloadAllTimelines()
            }
            .store(in: &cancellables)
    }

    func setTestMode(_ enabled: Bool) {
        settingsRepository.setTestMode(enabled)
    }
}
