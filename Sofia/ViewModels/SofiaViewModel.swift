import SwiftUI
import Combine

@MainActor
class SofiaViewModel: ObservableObject {

    // MARK: - Published state
    @Published var totalMW: Double = 0
    @Published var perBMU: [String: Double] = [:]
    @Published var history: [AggregatedPoint] = []

    @Published var lastAPIUpdate: Date?        // latest time_from across all BMUs
    @Published var lastFetch: Date?            // when we last polled

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Chart window
    @Published var chartHours: Double = 48     // visible window in hours

    // MARK: - Private
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 60   // poll every 60 s

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

        do {
            // 1. Find the time window: last 7 days up to now
            let to   = Date()
            let from = to.addingTimeInterval(-7 * 24 * 3600)

            // 2. Fetch all BMUs in parallel
            let bmuIds = BMU.allCases.map(\.rawValue)
            async let results: [[PnResponse]] = withThrowingTaskGroup(of: [PnResponse].self) { group in
                for bmu in bmuIds {
                    group.addTask {
                        (try? await SofiaAPIService.shared.pnData(bmuId: bmu, from: from, to: to)) ?? []
                    }
                }
                var all: [[PnResponse]] = []
                for try await r in group { all.append(r) }
                return all
            }

            let allData = try await results.flatMap { $0 }

            // 3. Build per-BMU latest production
            var latestPerBMU: [String: PnResponse] = [:]
            for point in allData {
                if let existing = latestPerBMU[point.bmuId] {
                    if point.timeFrom > existing.timeFrom { latestPerBMU[point.bmuId] = point }
                } else {
                    latestPerBMU[point.bmuId] = point
                }
            }
            perBMU = latestPerBMU.mapValues(\.levelMw)
            totalMW = perBMU.values.reduce(0, +)

            // Latest time across all BMUs
            lastAPIUpdate = latestPerBMU.values.map(\.timeFrom).max()

            // 4. Aggregate history by time bucket (sum all BMUs per settlement period)
            var buckets: [Date: Double] = [:]
            for point in allData {
                buckets[point.timeFrom, default: 0] += point.levelMw
            }
            history = buckets
                .map { AggregatedPoint(time: $0.key, totalMw: $0.value) }
                .sorted { $0.time < $1.time }

            lastFetch = Date()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered history for the chart window
    var visibleHistory: [AggregatedPoint] {
        guard !history.isEmpty else { return [] }
        let cutoff = Date().addingTimeInterval(-chartHours * 3600)
        let filtered = history.filter { $0.time >= cutoff }
        return filtered.isEmpty ? history : filtered
    }

    // MARK: - Private helpers
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }
}
