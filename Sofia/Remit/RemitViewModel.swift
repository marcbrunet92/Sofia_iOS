import Combine
import Foundation
import Observation
import SofiaCore

struct RemitUiState {
    var isLoading = true
    var isRefreshing = false
    var testMode = false
    var remits: [RemitNotice] = []
    /// Avis en vigueur puis à venir, regroupés quand ils concernent tout le parc.
    var sections = RemitSections()
    var units: UnitsData?
    var lastFetchTimestamp: Date?
    var errorMessageKey: String?
}

/// Équivalent de ui/remit/RemitViewModel.kt.
@Observable
final class RemitViewModel {
    private(set) var uiState = RemitUiState()

    private let repository: SofiaRemitRepository

    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var observeTask: Task<Void, Never>?
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(repository: SofiaRemitRepository, settingsRepository: SettingsRepository) {
        self.repository = repository

        settingsRepository.testMode
            .sink { [weak self] enabled in
                self?.onTestModeChanged(enabled)
            }
            .store(in: &cancellables)

        // Rafraîchissement automatique toutes les 120 s
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(120))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    private func onTestModeChanged(_ enabled: Bool) {
        uiState.testMode = enabled
        startObserving(testMode: enabled)
        refresh(forceLoading: uiState.remits.isEmpty)
    }

    private func startObserving(testMode: Bool) {
        observeTask?.cancel()
        observeTask = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.reloadFromStore(testMode: testMode)
        }
    }

    private func reloadFromStore(testMode: Bool) async {
        let remits = await repository.remits(testMode: testMode)
        guard !Task.isCancelled, uiState.testMode == testMode else { return }
        let now = Date()
        var state = uiState
        state.remits = remits
        state.sections = groupRemits(remits, units: SofiaConstants.bmus(testMode: testMode), now: now)
        state.units = UnitsData(
            testMode: testMode,
            units: computeUnitStatuses(remits, testMode: testMode, now: now),
            fetchedAt: now,
            fromCache: false
        )
        state.isLoading = false
        state.isRefreshing = false
        uiState = state
    }

    @discardableResult
    func refresh(forceLoading: Bool = false) -> Task<Void, Never> {
        refreshTask?.cancel()
        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.performRefresh(forceLoading: forceLoading)
        }
        refreshTask = task
        return task
    }

    private func performRefresh(forceLoading: Bool) async {
        let hasExistingData = !uiState.remits.isEmpty
        var state = uiState
        state.isLoading = forceLoading || !hasExistingData
        state.isRefreshing = hasExistingData
        // NB : Android affiche ici l'erreur dès le début du rafraîchissement ; on l'efface
        // plutôt (comme GraphViewModel) pour ne pas faire clignoter la bannière à chaque rafraîchissement.
        state.errorMessageKey = nil
        uiState = state

        let testMode = uiState.testMode
        do {
            try await repository.refresh(testMode: testMode)
            guard !Task.isCancelled else { return }
            uiState.lastFetchTimestamp = Date()
            uiState.errorMessageKey = nil
        } catch {
            if Task.isCancelled || isCancellation(error) { return }
            print("RemitViewModel: refresh failed: \(error)")
            var failed = uiState
            failed.isLoading = false
            failed.isRefreshing = false
            failed.lastFetchTimestamp = Date()
            failed.errorMessageKey = "error_unable_to_refresh_remit"
            uiState = failed
        }
        await reloadFromStore(testMode: testMode)
    }

    func dismissError() {
        uiState.errorMessageKey = nil
    }
}
