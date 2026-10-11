import Combine
import Foundation
import Observation
import SofiaCore

enum GraphDataset: CaseIterable, Hashable {
    case weather
    case pn
    case b1610

    var labelKey: String {
        switch self {
        case .weather: return "dataset_weather"
        case .pn: return "dataset_pn"
        case .b1610: return "dataset_b1610"
        }
    }
}

struct GraphUiState {
    var isLoading = true
    var isRefreshing = false
    var selectedWindow: TimeWindow = .all
    /// Ordre d'insertion conservé, comme le `Set` (LinkedHashSet) Kotlin.
    var selectedDatasets: [GraphDataset] = [.pn]
    // Données brutes
    /// MW
    var pnPoints: [GraphPoint] = []
    /// MWh par 30 min
    var b1610PointsMwh: [GraphPoint] = []
    /// Vitesse du vent telle que renvoyée par l'API
    var weatherPoints: [GraphPoint] = []
    // Méta
    var latestDataTimestamp: Date?
    var lastFetchTimestamp: Date?
    var errorMessageKey: String?
    var testMode = false

    var hasData: Bool {
        !pnPoints.isEmpty || !b1610PointsMwh.isEmpty || !weatherPoints.isEmpty
    }
}

/// Équivalent de ui/graph/GraphViewModel.kt.
@Observable
final class GraphViewModel {
    private(set) var uiState = GraphUiState()

    private let productionRepository: SofiaProductionRepository
    private let b1610Repository: SofiaB1610Repository
    private let weatherRepository: SofiaWeatherRepository

    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var observeTask: Task<Void, Never>?
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(
        productionRepository: SofiaProductionRepository,
        b1610Repository: SofiaB1610Repository,
        weatherRepository: SofiaWeatherRepository,
        settingsRepository: SettingsRepository
    ) {
        self.productionRepository = productionRepository
        self.b1610Repository = b1610Repository
        self.weatherRepository = weatherRepository

        settingsRepository.testMode
            .sink { [weak self] enabled in
                self?.onTestModeChanged(enabled)
            }
            .store(in: &cancellables)

        // Rafraîchissement automatique toutes les 60 s
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    private func onTestModeChanged(_ enabled: Bool) {
        uiState.testMode = enabled
        startObserving(testMode: enabled)
        refresh(forceLoading: !uiState.hasData)
    }

    /// Équivalent de la collecte des Flow Room : publie le contenu du cache local.
    private func startObserving(testMode: Bool) {
        observeTask?.cancel()
        observeTask = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.reloadFromStore(testMode: testMode)
        }
    }

    private func reloadFromStore(testMode: Bool) async {
        let production = productionRepository
        let actual = b1610Repository
        let weather = weatherRepository
        async let pnSnapshot = production.snapshot(testMode: testMode)
        async let b1610Snapshot = actual.snapshot(testMode: testMode)
        async let weatherSnapshot = weather.snapshot()
        let pn = await pnSnapshot
        let b1610 = await b1610Snapshot
        let wind = await weatherSnapshot
        guard !Task.isCancelled, uiState.testMode == testMode else { return }

        let latest = [pn.latestDataTimestamp, b1610.latestDataTimestamp, wind.latestDataTimestamp]
            .compactMap { $0 }
            .max()
        var state = uiState
        state.pnPoints = pn.points
        state.b1610PointsMwh = b1610.points
        state.weatherPoints = wind.points
        state.latestDataTimestamp = latest
        state.isLoading = false
        state.isRefreshing = false
        uiState = state
    }

    func selectWindow(_ window: TimeWindow) {
        uiState.selectedWindow = window
    }

    func toggleDataset(_ dataset: GraphDataset) {
        var datasets = uiState.selectedDatasets
        if let index = datasets.firstIndex(of: dataset) {
            datasets.remove(at: index)
        } else {
            datasets.append(dataset)
        }
        // Au moins un jeu de données reste sélectionné
        uiState.selectedDatasets = datasets.isEmpty ? [dataset] : datasets
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
        let hasExistingData = uiState.hasData
        var state = uiState
        state.isLoading = forceLoading || !hasExistingData
        state.isRefreshing = hasExistingData
        state.errorMessageKey = nil
        uiState = state

        let testMode = uiState.testMode
        let production = productionRepository
        let actual = b1610Repository
        let weather = weatherRepository
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await production.refresh(testMode: testMode) }
                group.addTask { try await actual.refresh(testMode: testMode) }
                group.addTask { try await weather.refresh() }
                try await group.waitForAll()
            }
            guard !Task.isCancelled else { return }
            uiState.lastFetchTimestamp = Date()
            uiState.errorMessageKey = nil
        } catch {
            if Task.isCancelled || isCancellation(error) { return }
            print("GraphViewModel: refresh failed: \(error)")
            var failed = uiState
            failed.isLoading = false
            failed.isRefreshing = false
            failed.lastFetchTimestamp = Date()
            failed.errorMessageKey = "error_unable_to_refresh_data"
            uiState = failed
        }
        // Les tables mises à jour sont republiées, comme les émissions Room
        await reloadFromStore(testMode: testMode)
    }

    func dismissError() {
        uiState.errorMessageKey = nil
    }
}
