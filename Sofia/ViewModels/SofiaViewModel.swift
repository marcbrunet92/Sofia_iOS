import SwiftUI
import Combine
import SofiaCore

@MainActor
class SofiaViewModel: ObservableObject {

    // MARK: - Settings
    @AppStorage("testMode") var testMode: Bool = false {
        didSet { Task { await refresh() } }
    }

    var mode: AppMode { testMode ? .test : .normal }

    // MARK: - Published state
    @Published var totalMW: Double = 0
    @Published var perBMU: [String: Double] = [:]
    @Published var history: [AggregatedPoint] = []

    @Published var lastAPIUpdate: Date?
    @Published var lastFetch: Date?

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Chart window
    @Published var chartHours: Double = 48

    // MARK: - Private
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 60

    // MARK: - Init
    init() {
        Task { await refresh() }
        startTimer()
    }

    deinit { timer?.invalidate() }

    // MARK: - Public
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let bmuIds = mode.bmuIds
        let to   = Date()
        let from = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1))!

        do {
            let allData: [PnResponse] = try await withThrowingTaskGroup(of: [PnResponse].self) { group in
                for bmu in bmuIds {
                    group.addTask {
                        (try? await SofiaAPIService.shared.pnData(bmuId: bmu, from: from, to: to)) ?? []
                    }
                }
                var results: [PnResponse] = []
                for try await r in group { results.append(contentsOf: r) }
                return results
            }

            // Latest value per BMU
            let latestPerBMU = allData.latestPerBMU()
            perBMU = latestPerBMU.mapValues(\.levelMw)
            totalMW = perBMU.values.reduce(0, +)
            history = allData.aggregatedHistory()

            lastFetch = Date()
            
            await refreshRemits()

            await refreshTopProduction()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered history for chart window
    var visibleHistory: [AggregatedPoint] {
        guard !history.isEmpty else { return [] }
        if chartHours == 0 { return history }
        let cutoff = Date().addingTimeInterval(-chartHours * 3600)
        let filtered = history.filter { $0.time >= cutoff }
        return filtered.isEmpty ? history : filtered
    }
    var capacityMW: Double { mode.capacityMW }

    var capacityFactor: Double { min(totalMW / capacityMW, 1.0) }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }
    
    @Published var remits: [RemitResponse] = []
    @Published var isLoadingRemits = false
    @Published var remitError: String?

    func refreshRemits() async {
        isLoadingRemits = true
        remitError = nil
        defer { isLoadingRemits = false }

        do {
            var all: [RemitResponse] = []
            for bmuId in mode.bmuIds {
                let results = (try? await SofiaAPIService.shared.listRemits(bmuId: bmuId, limit: 100)) ?? []
                all.append(contentsOf: results)
            }
            // Sort: active first, then by most recent publish time
            remits = all.sorted {
                if $0.isCurrentlyActive != $1.isCurrentlyActive { return $0.isCurrentlyActive }
                return ($0.publishTime ?? .distantPast) > ($1.publishTime ?? .distantPast)
            }
        } catch {
            remitError = error.localizedDescription
        }
    }
    // MARK: - Records
    @Published var topProduction: PnTopProductionWindows?
    @Published var isLoadingRecords = false

    func refreshTopProduction() async {
        isLoadingRecords = true
        defer { isLoadingRecords = false }
        topProduction = try? await SofiaAPIService.shared.topProduction()
    }
}
