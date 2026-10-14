import Foundation

/// Équivalent de widget/modern/SofiaWidgetData.kt.

// MARK: - Modèles

public struct LiveData: Codable, Sendable {
    public let testMode: Bool
    /// MW (PN)
    public let committed: [GraphPoint]
    /// MW (B1610 MWh/30 min × 2)
    public let actual: [GraphPoint]
    public let from: Date
    public let to: Date
    public var fromCache: Bool

    public init(testMode: Bool, committed: [GraphPoint], actual: [GraphPoint], from: Date, to: Date, fromCache: Bool) {
        self.testMode = testMode
        self.committed = committed
        self.actual = actual
        self.from = from
        self.to = to
        self.fromCache = fromCache
    }

    public var currentMw: Double { committed.last?.quantity ?? 0 }
    public var actualMw: Double? { actual.last?.quantity }
}

public enum AvailabilityLevel: Sendable {
    case good, warn, bad
}

public struct UnitStatus: Codable, Hashable, Sendable {
    public let bmuId: String
    public let normalMw: Double?
    public let availableMw: Double?
    public let hasNotice: Bool
    public let cause: String?

    public init(bmuId: String, normalMw: Double?, availableMw: Double?, hasNotice: Bool, cause: String?) {
        self.bmuId = bmuId
        self.normalMw = normalMw
        self.availableMw = availableMw
        self.hasNotice = hasNotice
        self.cause = cause
    }

    /// « T_SOFOW-11 » → « SOFOW-11 »
    public var label: String { bmuId.removingPrefix("T_") }

    /// « T_SOFOW-11 » → « 11 »
    public var shortLabel: String {
        let parts = bmuId.split(separator: "-", omittingEmptySubsequences: false)
        let afterDash = parts.last.map { String($0) } ?? bmuId
        return afterDash.removingPrefix("T_")
    }

    public var fraction: Double {
        if let normal = normalMw, normal > 0, let available = availableMw {
            return min(max(available / normal, 0), 1)
        }
        return 1
    }

    /// `statusColor()` : vert si pleine capacité, orange si partielle, rouge si nulle.
    public var level: AvailabilityLevel {
        if fraction >= 0.999 { return .good }
        if fraction > 0 { return .warn }
        return .bad
    }
}

/// Puissance utilisable prévue par jour (UOU2T14D), pour le widget « 14 prochains jours ».
public struct NextDaysData: Codable, Sendable {
    public let testMode: Bool
    public let days: [UouDay]
    public let fetchedAt: Date
    public var fromCache: Bool

    public init(testMode: Bool, days: [UouDay], fetchedAt: Date, fromCache: Bool) {
        self.testMode = testMode
        self.days = days
        self.fetchedAt = fetchedAt
        self.fromCache = fromCache
    }
}

/// Production annoncée de Sofia (PN) comparée à l'éolien de Grande-Bretagne (AGWS) sur la même
/// demi-heure, la dernière publiée par AGWS.
public struct GbShareData: Codable, Sendable {
    public let testMode: Bool
    public let timeFrom: Date?
    public let sofiaMw: Double?
    public let offshoreMw: Double?
    public let onshoreMw: Double?
    public let fetchedAt: Date
    public var fromCache: Bool

    public init(
        testMode: Bool,
        timeFrom: Date?,
        sofiaMw: Double?,
        offshoreMw: Double?,
        onshoreMw: Double?,
        fetchedAt: Date,
        fromCache: Bool
    ) {
        self.testMode = testMode
        self.timeFrom = timeFrom
        self.sofiaMw = sofiaMw
        self.offshoreMw = offshoreMw
        self.onshoreMw = onshoreMw
        self.fetchedAt = fetchedAt
        self.fromCache = fromCache
    }

    /// Part de Sofia dans l'éolien en mer GB, en %.
    public var offshoreSharePercent: Double? { shareOf(offshoreMw) }

    /// Part de Sofia dans tout l'éolien GB (en mer + terrestre), en %.
    public var windSharePercent: Double? {
        guard let offshoreMw, let onshoreMw else { return nil }
        return shareOf(offshoreMw + onshoreMw)
    }

    private func shareOf(_ totalMw: Double?) -> Double? {
        guard let sofiaMw, let totalMw, totalMw > 0 else { return nil }
        return sofiaMw / totalMw * 100
    }
}

public struct UnitsData: Codable, Sendable {
    public let testMode: Bool
    public let units: [UnitStatus]
    public let fetchedAt: Date
    public var fromCache: Bool

    public init(testMode: Bool, units: [UnitStatus], fetchedAt: Date, fromCache: Bool) {
        self.testMode = testMode
        self.units = units
        self.fetchedAt = fetchedAt
        self.fromCache = fromCache
    }

    public var totalAvailable: Double { units.reduce(0) { $0 + ($1.availableMw ?? 0) } }
    public var totalNormal: Double { units.reduce(0) { $0 + ($1.normalMw ?? 0) } }
}

// MARK: - Disponibilité par unité

/// Disponibilité par unité à l'instant `now` d'après les avis REMIT (sans avis → pleine capacité nominale).
public func computeUnitStatuses(_ notices: [RemitNotice], testMode: Bool, now: Date) -> [UnitStatus] {
    let bmus = SofiaConstants.bmus(testMode: testMode)
    // En mode test (T_HEYM11) la capacité nominale d'une unité est inconnue sans avis.
    let nominal: Double? = testMode ? nil : SofiaConstants.maxCapacityMw / Double(SofiaConstants.bmus.count)
    return bmus.map { id in
        let active = notices.filter { $0.bmuId == id && $0.isInEffect(at: now) }
        let normal = active.compactMap { $0.normalCapacityMw }.first ?? nominal
        let available = active.compactMap { $0.availableMw }.min() ?? normal
        var cause: String? = nil
        if let firstCause = active.first?.cause, !firstCause.isBlank {
            cause = firstCause
        }
        return UnitStatus(
            bmuId: id,
            normalMw: normal,
            availableMw: available,
            hasNotice: !active.isEmpty,
            cause: cause
        )
    }
}

extension RemitNotice {
    func isInEffect(at time: Date) -> Bool {
        (eventStartTime.map { $0 <= time } ?? true) && (eventEndTime.map { $0 >= time } ?? true)
    }

    var availableMw: Double? {
        if let availableCapacityMw { return availableCapacityMw }
        if let normal = normalCapacityMw, let unavailable = unavailableCapacityMw { return normal - unavailable }
        return nil
    }
}

extension String {
    func removingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}

// MARK: - Chargement

public enum SofiaWidgetData {
    /// Récupère seulement la fenêtre demandée (24 h par défaut) au lieu de tout l'historique, et lit
    /// le cache local en secours. On n'écrit volontairement pas dans le cache de l'app : un
    /// rafraîchissement partiel tronquerait son historique.
    ///
    /// - Parameters:
    ///   - window: durée affichée ; `nil` = tout l'historique.
    ///   - includeActual: `false` = le B1610 n'est pas chargé du tout.
    public static func loadLive(
        window: TimeInterval? = 24 * 3_600,
        includeActual: Bool = true,
        api: SofiaApiService = .shared,
        store: SofiaLocalStore = .shared
    ) async -> LiveData {
        let testMode = SofiaSettings.testMode
        let to = Date()
        let from = window.map { to.addingTimeInterval(-$0) } ?? SofiaConstants.historyStart
        let windowName = window.map { String(Int($0 / 60)) } ?? "all"
        let snapshotName = "live_\(windowName)_\(includeActual ? "a" : "c")"
        let fromString = ApiTime.format(from)
        let toString = ApiTime.format(to)

        let fresh: ([GraphPoint], [GraphPoint])? = try? await withTimeout(seconds: 30) {
            async let committed = SofiaWidgetData.fetchCommitted(api: api, from: fromString, to: toString, testMode: testMode)
            async let actual = SofiaWidgetData.fetchActual(include: includeActual, api: api, from: fromString, to: toString, testMode: testMode)
            let committedPoints = try await committed
            let actualPoints = try await actual
            return (committedPoints, actualPoints)
        }

        if let fresh {
            let data = LiveData(testMode: testMode, committed: fresh.0, actual: fresh.1, from: from, to: to, fromCache: false)
            SofiaWidgetSnapshots.saveLive(data, name: snapshotName)
            return data
        }

        let committed = await store.productionPoints(testMode: testMode).filter { $0.timeFrom >= from }
        let actual: [GraphPoint]
        if includeActual {
            actual = await store.b1610Points(testMode: testMode)
                .filter { $0.timeFrom >= from }
                .map { $0.with(quantity: $0.quantity * 2) }
        } else {
            actual = []
        }
        let cached = LiveData(testMode: testMode, committed: committed, actual: actual, from: from, to: to, fromCache: true)
        // Cache vide/périmé (app pas ouverte depuis longtemps) → dernier snapshot du widget
        if !committed.isEmpty { return cached }
        if let snapshot = SofiaWidgetSnapshots.loadLive(name: snapshotName), snapshot.testMode == testMode {
            return snapshot
        }
        return cached
    }

    /// Disponibilité par unité d'après les avis REMIT actifs (sans avis → pleine capacité nominale).
    public static func loadUnits(
        api: SofiaApiService = .shared,
        store: SofiaLocalStore = .shared
    ) async -> UnitsData {
        let testMode = SofiaSettings.testMode
        let now = Date()

        let fresh: [RemitNotice]? = try? await withTimeout(seconds: 20) {
            try await fetchActiveRemits(api: api, testMode: testMode)
        }

        if fresh == nil, let snapshot = SofiaWidgetSnapshots.loadUnits(), snapshot.testMode == testMode {
            return snapshot
        }

        let notices: [RemitNotice]
        if let fresh {
            notices = fresh
        } else {
            notices = await store.remitNotices(testMode: testMode)
        }
        let data = UnitsData(
            testMode: testMode,
            units: computeUnitStatuses(notices, testMode: testMode, now: now),
            fetchedAt: now,
            fromCache: fresh == nil
        )
        if fresh != nil {
            SofiaWidgetSnapshots.saveUnits(data)
        }
        return data
    }

    /// Prévision UOU2T14D à partir d'aujourd'hui ; en secours le dernier instantané, puis le cache de l'app.
    public static func loadNextDays(
        api: SofiaApiService = .shared,
        store: SofiaLocalStore = .shared
    ) async -> NextDaysData {
        let testMode = SofiaSettings.testMode
        let now = Date()

        let fresh: [UouDay]? = try? await withTimeout(seconds: 20) {
            try await api.getUou(testMode: testMode)
                .map { UouDay(date: $0.forecastDate, outputUsableMw: $0.outputUsable) }
        }

        if let fresh {
            let data = NextDaysData(testMode: testMode, days: fresh, fetchedAt: now, fromCache: false)
            SofiaWidgetSnapshots.saveNextDays(data)
            return data
        }
        if let snapshot = SofiaWidgetSnapshots.loadNextDays(), snapshot.testMode == testMode {
            return snapshot
        }
        let cached = await store.uouDays(testMode: testMode)
        return NextDaysData(testMode: testMode, days: cached, fetchedAt: now, fromCache: true)
    }

    /// Dernière demi-heure AGWS et PN de Sofia sur la même demi-heure (le B1610 arrive trop tard).
    /// En secours le dernier instantané, puis le cache de l'app.
    public static func loadGbShare(
        api: SofiaApiService = .shared,
        store: SofiaLocalStore = .shared
    ) async -> GbShareData {
        let testMode = SofiaSettings.testMode
        let now = Date()

        let fresh: GbShareData? = try? await withTimeout(seconds: 20) {
            let gb = try await api.getAgwsLatest()
            let timeFrom = ApiTime.parseInstant(gb.timeFrom)
            var sofiaMw: Double? = nil
            if let timeFrom {
                let entries = try await api.getProduction(
                    testMode: testMode,
                    timeFrom: ApiTime.format(timeFrom),
                    timeTo: ApiTime.format(timeFrom.addingTimeInterval(30 * 60))
                )
                sofiaMw = aggregateProduction(entries, testMode: testMode)
                    .first(where: { $0.timeFrom == timeFrom })?.quantity
            }
            return GbShareData(
                testMode: testMode,
                timeFrom: timeFrom,
                sofiaMw: sofiaMw,
                offshoreMw: gb.windOffshoreMw,
                onshoreMw: gb.windOnshoreMw,
                fetchedAt: now,
                fromCache: false
            )
        }

        if let fresh {
            SofiaWidgetSnapshots.saveGbShare(fresh)
            return fresh
        }
        if let snapshot = SofiaWidgetSnapshots.loadGbShare(), snapshot.testMode == testMode {
            return snapshot
        }
        let gb = await store.gbContext()
        var sofiaMw: Double? = nil
        if let gb {
            let points = await store.productionPoints(testMode: testMode)
            sofiaMw = points.last(where: { $0.timeFrom == gb.timeFrom })?.quantity
        }
        return GbShareData(
            testMode: testMode,
            timeFrom: gb?.timeFrom,
            sofiaMw: sofiaMw,
            offshoreMw: gb?.windOffshoreMw,
            onshoreMw: gb?.windOnshoreMw,
            fetchedAt: now,
            fromCache: true
        )
    }

    /// Somme Sofia calculée par le serveur (ou unité de test) : une requête.
    private static func fetchCommitted(
        api: SofiaApiService,
        from: String,
        to: String,
        testMode: Bool
    ) async throws -> [GraphPoint] {
        let entries = try await api.getProduction(testMode: testMode, timeFrom: from, timeTo: to)
        return aggregateProduction(entries, testMode: testMode)
    }

    /// B1610 en MW (MWh par demi-heure × 2) ; rien n'est chargé si `include` est faux.
    private static func fetchActual(
        include: Bool,
        api: SofiaApiService,
        from: String,
        to: String,
        testMode: Bool
    ) async throws -> [GraphPoint] {
        guard include else { return [] }
        let entries = try await api.getB1610(testMode: testMode, timeFrom: from, timeTo: to)
        return aggregateB1610(entries, testMode: testMode)
            .map { $0.with(quantity: $0.quantity * 2) }
    }
}
