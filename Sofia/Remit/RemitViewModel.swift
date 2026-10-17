import Foundation
import Observation
import SofiaCore

struct RemitUiState {
    var isLoading = true
    var isRefreshing = false
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

    init(repository: SofiaRemitRepository) {
        self.repository = repository

        startObserving()
        refresh(forceLoading: uiState.remits.isEmpty)

        // Rafraîchissement automatique toutes les 120 s
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(120))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    private func startObserving() {
        observeTask?.cancel()
        observeTask = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.reloadFromStore()
        }
    }

    private func reloadFromStore() async {
        let remits = await repository.remits()
        guard !Task.isCancelled else { return }
        let now = Date()
        var state = uiState
        state.remits = remits
        state.sections = groupRemits(remits, units: SofiaConstants.bmus, now: now)
        state.units = UnitsData(
            units: computeUnitStatuses(remits, now: now),
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
        uiState = state

        do {
            try await repository.refresh()
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
        await reloadFromStore()
    }

    func dismissError() {
        uiState.errorMessageKey = nil
    }
}
