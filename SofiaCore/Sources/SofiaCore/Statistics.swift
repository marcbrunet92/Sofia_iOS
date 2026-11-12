import Foundation

/// Statistiques de production calculées sur les séries en cache (onglet Statistiques).

public enum StatsPeriod: String, CaseIterable, Codable, Sendable {
    case day = "DAY"
    case week = "WEEK"
    case month = "MONTH"
    case all = "ALL"

    /// Durée de la période en secondes ; `nil` pour tout l'historique.
    public var duration: TimeInterval? {
        switch self {
        case .day: return 86_400
        case .week: return 7 * 86_400
        case .month: return 30 * 86_400
        case .all: return nil
        }
    }

    /// Libellé du chip (clé de localisation, les mêmes que les fenêtres du graphique).
    public var labelKey: String {
        switch self {
        case .day: return "time_window_24h"
        case .week: return "time_window_7d"
        case .month: return "time_window_1m"
        case .all: return "time_window_all"
        }
    }

    /// Début de la période ; `nil` pour tout l'historique.
    public func start(now: Date) -> Date? {
        duration.map { now.addingTimeInterval(-$0) }
    }
}

/// Bilan d'une période, calculé sur une série de puissances moyennes (MW) par intervalle.
public struct PeriodStats: Equatable, Sendable {
    /// Début du premier intervalle et fin du dernier intervalle pris en compte.
    public let from: Date
    public let to: Date
    /// Heures couvertes par les données (les trous ne comptent pas).
    public let hours: Double
    public let energyMwh: Double
    public let averageMw: Double
    /// Puissance moyenne ÷ capacité installée, entre 0 et 1.
    public let capacityFactor: Double
    public let peakMw: Double
    public let peakDate: Date?
    /// Part du temps avec une production strictement positive, entre 0 et 1.
    public let generatingShare: Double

    /// Foyers alimentés sur un an à cette puissance moyenne.
    public var equivalentHomes: Double {
        averageMw * 8_760 / SofiaConstants.homeAnnualMwh
    }
}

/// Bilan des `points` (MW par intervalle [timeFrom, timeTo[) sur la période qui se termine à `now`.
/// Les intervalles à venir (le PN est publié jusqu'à 1 h à l'avance) sont ignorés.
/// `nil` s'il n'y a aucune donnée sur la période.
public func periodStats(
    _ points: [GraphPoint],
    period: StatsPeriod,
    capacityMw: Double,
    now: Date = Date()
) -> PeriodStats? {
    let start = period.start(now: now)
    var hours = 0.0
    var energy = 0.0
    var generatingHours = 0.0
    var peak: GraphPoint?
    var first: Date?
    var last: Date?
    for point in points {
        if let start, point.timeFrom < start { continue }
        if point.timeFrom >= now { continue }
        let duration = point.timeTo.timeIntervalSince(point.timeFrom) / 3_600
        guard duration > 0 else { continue }
        hours += duration
        energy += point.quantity * duration
        if point.quantity > 0 { generatingHours += duration }
        if peak == nil || point.quantity > (peak?.quantity ?? 0) { peak = point }
        if first == nil || point.timeFrom < (first ?? point.timeFrom) { first = point.timeFrom }
        if last == nil || point.timeTo > (last ?? point.timeTo) { last = point.timeTo }
    }
    guard hours > 0, let first, let last else { return nil }
    let average = energy / hours
    return PeriodStats(
        from: first,
        to: last,
        hours: hours,
        energyMwh: energy,
        averageMw: average,
        capacityFactor: capacityMw > 0 ? min(max(average / capacityMw, 0), 1) : 0,
        peakMw: peak?.quantity ?? 0,
        peakDate: peak?.timeFrom,
        generatingShare: generatingHours / hours
    )
}

/// Énergie produite pendant un jour (fuseau de l'appareil).
public struct DailyEnergy: Hashable, Identifiable, Sendable {
    /// Minuit du jour, dans le fuseau du calendrier utilisé.
    public let day: Date
    public let energyMwh: Double
    /// `true` : mesurée au compteur (B1610). `false` : estimée d'après la production annoncée (PN).
    public let metered: Bool

    public var id: Date { day }

    public init(day: Date, energyMwh: Double, metered: Bool) {
        self.day = day
        self.energyMwh = energyMwh
        self.metered = metered
    }
}

/// Énergie des `days` derniers jours, aujourd'hui inclus, du plus ancien au plus récent.
///
/// Le compteur (B1610, MWh par demi-heure) arrive plusieurs jours après : un jour qu'il couvre
/// entièrement prend sa valeur, les autres sont estimés d'après le PN (MW × durée).
public func dailyEnergy(
    pnMw: [GraphPoint],
    b1610Mwh: [GraphPoint],
    days: Int,
    now: Date = Date(),
    calendar: Calendar = .current
) -> [DailyEnergy] {
    guard days > 0 else { return [] }
    let today = calendar.startOfDay(for: now)
    guard let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

    struct Bucket {
        var announcedMwh = 0.0
        var announcedHours = 0.0
        var meteredMwh = 0.0
        var meteredHours = 0.0
    }
    var buckets: [Date: Bucket] = [:]

    for point in pnMw where point.timeFrom >= firstDay && point.timeFrom < now {
        let hours = point.timeTo.timeIntervalSince(point.timeFrom) / 3_600
        guard hours > 0 else { continue }
        let day = calendar.startOfDay(for: point.timeFrom)
        buckets[day, default: Bucket()].announcedMwh += point.quantity * hours
        buckets[day, default: Bucket()].announcedHours += hours
    }
    for point in b1610Mwh where point.timeFrom >= firstDay && point.timeFrom < now {
        let hours = point.timeTo.timeIntervalSince(point.timeFrom) / 3_600
        guard hours > 0 else { continue }
        let day = calendar.startOfDay(for: point.timeFrom)
        buckets[day, default: Bucket()].meteredMwh += point.quantity
        buckets[day, default: Bucket()].meteredHours += hours
    }

    var result: [DailyEnergy] = []
    result.reserveCapacity(days)
    var day = firstDay
    while day <= today {
        let bucket = buckets[day] ?? Bucket()
        let metered = bucket.meteredHours > 0 && bucket.meteredHours >= bucket.announcedHours - 0.01
        result.append(DailyEnergy(
            day: day,
            energyMwh: metered ? bucket.meteredMwh : bucket.announcedMwh,
            metered: metered
        ))
        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
        day = next
    }
    return result
}

/// Production moyenne observée pour une classe de vitesse de vent.
public struct PowerCurveBin: Hashable, Identifiable, Sendable {
    /// Bornes de la classe, en m/s.
    public let lowerMs: Double
    public let upperMs: Double
    public let averageMw: Double
    public let samples: Int

    public var centerMs: Double { (lowerMs + upperMs) / 2 }
    public var id: Double { lowerMs }

    public init(lowerMs: Double, upperMs: Double, averageMw: Double, samples: Int) {
        self.lowerMs = lowerMs
        self.upperMs = upperMs
        self.averageMw = averageMw
        self.samples = samples
    }
}

/// Courbe de puissance observée : production annoncée moyenne (MW) par classe de vent.
///
/// Chaque demi-heure de PN est associée au vent de l'heure qui la contient (météo horaire, km/h).
/// Les classes avec moins de `minSamples` demi-heures sont écartées.
public func powerCurve(
    pnMw: [GraphPoint],
    windKmh: [GraphPoint],
    from start: Date?,
    now: Date = Date(),
    binWidthMs: Double = 2,
    minSamples: Int = 4
) -> [PowerCurveBin] {
    guard binWidthMs > 0 else { return [] }
    func hourKey(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 / 3_600).rounded(.down))
    }
    var windByHour: [Int: Double] = [:]
    windByHour.reserveCapacity(windKmh.count)
    for point in windKmh {
        windByHour[hourKey(point.timeFrom)] = point.quantity / 3.6
    }

    var sums: [Int: (total: Double, count: Int)] = [:]
    for point in pnMw {
        if let start, point.timeFrom < start { continue }
        if point.timeFrom >= now { continue }
        guard let wind = windByHour[hourKey(point.timeFrom)], wind >= 0 else { continue }
        let bin = Int((wind / binWidthMs).rounded(.down))
        let current = sums[bin] ?? (0, 0)
        sums[bin] = (current.total + point.quantity, current.count + 1)
    }
    return sums
        .filter { $0.value.count >= minSamples }
        .map { bin, sum in
            PowerCurveBin(
                lowerMs: Double(bin) * binWidthMs,
                upperMs: Double(bin + 1) * binWidthMs,
                averageMw: sum.total / Double(sum.count),
                samples: sum.count
            )
        }
        .sorted { $0.lowerMs < $1.lowerMs }
}

// MARK: - Production par unité

/// Dernière production annoncée (PN) d'une unité.
public struct UnitOutput: Codable, Hashable, Identifiable, Sendable {
    public let bmuId: String
    public let outputMw: Double?
    public let capacityMw: Double?
    public let timeFrom: Date?

    public var id: String { bmuId }

    public init(bmuId: String, outputMw: Double?, capacityMw: Double?, timeFrom: Date?) {
        self.bmuId = bmuId
        self.outputMw = outputMw
        self.capacityMw = capacityMw
        self.timeFrom = timeFrom
    }

    /// « T_SOFOW-11 » → « 11 »
    public var shortLabel: String { unitNumber(bmuId) }

    /// Production ÷ capacité, entre 0 et 1.
    public var fraction: Double {
        guard let outputMw, let capacityMw, capacityMw > 0 else { return 0 }
        return min(max(outputMw / capacityMw, 0), 1)
    }
}

/// Dernière entrée de chaque unité : `entries[i]` est la série de `bmus[i]`.
public func latestUnitOutputs(bmus: [String], entries: [[PnEntryDto]]) -> [UnitOutput] {
    zip(bmus, entries).map { bmuId, series in
        let latest = series
            .compactMap { entry in ApiTime.parseUtc(entry.timeFrom).map { (time: $0, mw: entry.levelMw) } }
            .max { $0.time < $1.time }
        return UnitOutput(
            bmuId: bmuId,
            outputMw: latest?.mw,
            capacityMw: SofiaConstants.unitCapacitiesMw[bmuId],
            timeFrom: latest?.time
        )
    }
}

/// Production annoncée de chaque unité du parc (PN par BMU, sur les dernières heures).
public struct SofiaUnitsRepository: Sendable {
    private let api: SofiaApiService

    public init(api: SofiaApiService = .shared) {
        self.api = api
    }

    public func latestOutputs(now: Date = Date()) async throws -> [UnitOutput] {
        let api = self.api
        let from = ApiTime.format(now.addingTimeInterval(-6 * 3_600))
        let to = ApiTime.format(now.addingTimeInterval(3_600))
        let bmus = SofiaConstants.bmus
        let entries = try await concurrentMap(bmus) { bmuId in
            try await api.getProduction(bmuId: bmuId, timeFrom: from, timeTo: to)
        }
        return latestUnitOutputs(bmus: bmus, entries: entries)
    }
}

// MARK: - Rappels des alertes

/// Rappel à programmer pour une alerte : à son début ou à sa fin.
public struct AlertReminder: Sendable {
    public enum Kind: String, Sendable {
        case start
        case end
    }

    public let id: String
    public let kind: Kind
    public let fireDate: Date
    public let group: RemitGroup
}

/// Rappels des alertes en cours et à venir : un au début de chaque alerte à venir, un à la fin de
/// chaque alerte qui a une date de fin. Du plus proche au plus lointain, `limit` au plus
/// (iOS ne garde que 64 notifications programmées).
public func planAlertReminders(_ sections: RemitSections, now: Date = Date(), limit: Int = 40) -> [AlertReminder] {
    let margin: TimeInterval = 60
    var reminders: [AlertReminder] = []
    for group in sections.upcoming {
        if let start = group.start, start.timeIntervalSince(now) > margin {
            reminders.append(AlertReminder(id: "start." + group.id, kind: .start, fireDate: start, group: group))
        }
    }
    for group in sections.current + sections.upcoming {
        if let end = group.end, end.timeIntervalSince(now) > margin {
            reminders.append(AlertReminder(id: "end." + group.id, kind: .end, fireDate: end, group: group))
        }
    }
    return Array(reminders.sorted { $0.fireDate < $1.fireDate }.prefix(max(limit, 0)))
}
