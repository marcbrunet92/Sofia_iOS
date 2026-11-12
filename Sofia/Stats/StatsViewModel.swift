import Foundation
import Observation
import SofiaCore

struct StatsUiState {
    var period: StatsPeriod = .week
    /// Dernière production annoncée de chaque unité ; vide tant qu'elle n'a pas été reçue.
    var unitOutputs: [UnitOutput] = []
}

/// Onglet Statistiques : période choisie et production par unité. Les séries (PN, B1610, vent)
/// viennent du `GraphViewModel`, déjà chargées pour le graphique.
@Observable
final class StatsViewModel {
    private(set) var uiState = StatsUiState()

    private let unitsRepository: SofiaUnitsRepository

    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var pollingTask: Task<Void, Never>?

    init(unitsRepository: SofiaUnitsRepository) {
        self.unitsRepository = unitsRepository
        // Captures d'écran de l'App Store : période demandée au lancement
        if let period = ScreenshotOptions.statsPeriod {
            uiState.period = period
        }

        refresh()

        // Rafraîchissement automatique toutes les 5 min
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    func selectPeriod(_ period: StatsPeriod) {
        uiState.period = period
    }

    @discardableResult
    func refresh() -> Task<Void, Never> {
        refreshTask?.cancel()
        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
        refreshTask = task
        return task
    }

    private func performRefresh() async {
        let repository = unitsRepository
        do {
            let outputs = try await repository.latestOutputs()
            guard !Task.isCancelled else { return }
            uiState.unitOutputs = outputs
        } catch {
            // Carte secondaire : en cas d'échec on garde les dernières valeurs reçues
            if Task.isCancelled || isCancellation(error) { return }
            print("StatsViewModel: refresh failed: \(error)")
        }
    }
}
