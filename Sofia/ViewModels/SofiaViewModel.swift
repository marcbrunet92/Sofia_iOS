import SwiftUI
import SofiaCore
import Combine

@MainActor
final class SofiaViewModel: ObservableObject {

    @AppStorage("testMode") var testMode = false {
        didSet { Task { await refresh() } }
    }

    var mode: AppMode { testMode ? .test : .normal }

    @Published var lastFetch: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var weatherSnapshot: WeatherSnapshot?
    @Published var b1610Snapshot: B1610Snapshot?
    @Published var productionSnapshot: ProductionSnapshot?

    private var refreshTask: Task<Void, Never>?

    init() {
        Task { await refresh() }

        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await refresh()
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let weather = SofiaAPIService.shared.fetchWeatherSnapshot()
            async let b1610 = SofiaAPIService.shared.fetchB1610Snapshot(mode: mode)
            async let production = SofiaAPIService.shared.fetchProductionSnapshot(mode: mode)

            weatherSnapshot = try await weather
            b1610Snapshot = try await b1610
            productionSnapshot = try await production

            lastFetch = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
