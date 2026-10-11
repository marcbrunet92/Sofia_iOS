import Foundation

/// Équivalent de SofiaProductionRepository.kt : PN agrégé de toutes les BMU depuis HISTORY_START.
public struct SofiaProductionRepository: Sendable {
    private let api: SofiaApiService
    private let store: SofiaLocalStore

    public init(api: SofiaApiService = .shared, store: SofiaLocalStore = .shared) {
        self.api = api
        self.store = store
    }

    /// `observeProduction` : instantané du cache local.
    public func snapshot(testMode: Bool) async -> ProductionSnapshot {
        let points = await store.productionPoints(testMode: testMode)
        return ProductionSnapshot(
            points: points,
            currentMw: points.last?.quantity ?? 0,
            latestDataTimestamp: points.last?.timeTo,
            topProduction: calculateTopWindows(points)
        )
    }

    public func refresh(testMode: Bool) async throws {
        let api = self.api
        let from = ApiTime.format(SofiaConstants.historyStart)
        let to = ApiTime.format(Date())
        let entries = try await concurrentMap(SofiaConstants.bmus(testMode: testMode)) { bmuId in
            try await api.getProduction(bmuId: bmuId, timeFrom: from, timeTo: to)
        }.flatMap { $0 }
        let points = aggregateProduction(entries, testMode: testMode)
        await store.refreshProductionPoints(testMode: testMode, points: points)
    }
}

/// Équivalent de SofiaB1610Repository.kt : production réelle (MWh par demi-heure).
public struct SofiaB1610Repository: Sendable {
    private let api: SofiaApiService
    private let store: SofiaLocalStore

    public init(api: SofiaApiService = .shared, store: SofiaLocalStore = .shared) {
        self.api = api
        self.store = store
    }

    /// `observeB1610` : instantané du cache local.
    public func snapshot(testMode: Bool) async -> B1610Snapshot {
        let points = await store.b1610Points(testMode: testMode)
        return B1610Snapshot(
            points: points,
            latestDataTimestamp: points.last?.timeTo,
            topB1610: calculateTopWindows(points)
        )
    }

    public func refresh(testMode: Bool) async throws {
        let api = self.api
        let from = ApiTime.format(SofiaConstants.historyStart)
        let to = ApiTime.format(Date())
        // Comme sur Android, les records sont demandés en parallèle mais les échecs sont ignorés
        // et l'écran utilise les maxima recalculés depuis les points.
        async let top = Self.fetchTopProduction(api)
        let entries = try await concurrentMap(SofiaConstants.bmus(testMode: testMode)) { bmuId in
            try await api.getB1610(bmuId: bmuId, timeFrom: from, timeTo: to)
        }.flatMap { $0 }
        _ = await top
        let points = aggregateB1610(entries, testMode: testMode)
        await store.refreshB1610Points(testMode: testMode, points: points)
    }

    private static func fetchTopProduction(_ api: SofiaApiService) async -> TopWindows {
        guard let dto = try? await api.getB1610TopProduction() else { return .empty }
        return topWindows(from: dto)
    }
}

/// Équivalent de SofiaWeatherRepository.kt : vitesse du vent.
public struct SofiaWeatherRepository: Sendable {
    private let api: SofiaApiService
    private let store: SofiaLocalStore

    public init(api: SofiaApiService = .shared, store: SofiaLocalStore = .shared) {
        self.api = api
        self.store = store
    }

    /// `observeWeather` : instantané du cache local.
    public func snapshot() async -> WeatherSnapshot {
        let points = await store.weatherPoints()
        return WeatherSnapshot(
            points: points,
            latestWindSpeed: points.last?.quantity,
            latestDataTimestamp: points.last?.timeTo
        )
    }

    public func refresh() async throws {
        let entries = try await api.getWeather(
            timeFrom: ApiTime.format(SofiaConstants.historyStart),
            timeTo: ApiTime.format(Date())
        )
        await store.refreshWeatherPoints(weatherGraphPoints(entries))
    }
}

/// Équivalent de SofiaRemitRepository.kt : avis REMIT actifs de chaque BMU.
public struct SofiaRemitRepository: Sendable {
    private let api: SofiaApiService
    private let store: SofiaLocalStore

    public init(api: SofiaApiService = .shared, store: SofiaLocalStore = .shared) {
        self.api = api
        self.store = store
    }

    /// `observeRemits` : avis en cache, du plus récent au plus ancien.
    public func remits(testMode: Bool) async -> [RemitNotice] {
        await store.remitNotices(testMode: testMode)
    }

    public func refresh(testMode: Bool) async throws {
        let notices = try await fetchActiveRemits(api: api, testMode: testMode)
        await store.refreshRemitNotices(testMode: testMode, notices: notices)
    }
}

/// Appels REMIT partagés par l'app et le widget « disponibilité par unité ».
func fetchActiveRemits(api: SofiaApiService, testMode: Bool) async throws -> [RemitNotice] {
    let entries = try await concurrentMap(SofiaConstants.bmus(testMode: testMode)) { bmuId in
        try await api.getRemits(bmuId: bmuId, eventStatus: "Active", limit: 100, offset: 0)
    }.flatMap { $0 }
    let notices = distinctRemits(entries).map(remitNotice(from:))
    return notices.sorted { ($0.publishTime ?? .distantPast) > ($1.publishTime ?? .distantPast) }
}
