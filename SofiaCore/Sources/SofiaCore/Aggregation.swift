import Foundation

/// Transformations des repositories Android (aggregateProduction, aggregateB1610,
/// calculateTopProduction/calculateTopB1610, toGraphPoint, toEntity/toModel).

private struct SettlementKey: Hashable {
    let timeFrom: String
    let timeTo: String
    let settlementPeriod: Int
}

/// Somme les BMU par période de règlement pour obtenir le total Sofia.
public func aggregateProduction(_ entries: [PnEntryDto]) -> [GraphPoint] {
    aggregate(
        entries,
        key: { SettlementKey(timeFrom: $0.timeFrom, timeTo: $0.timeTo, settlementPeriod: $0.settlementPeriod) },
        timeFrom: { $0.timeFrom },
        timeTo: { $0.timeTo },
        quantity: { $0.levelMw }
    )
}

/// Même agrégation pour la production réelle (B1610, MWh par demi-heure).
public func aggregateB1610(_ entries: [B1610EntryDto]) -> [GraphPoint] {
    aggregate(
        entries,
        key: { SettlementKey(timeFrom: $0.timeFrom, timeTo: $0.timeTo, settlementPeriod: $0.settlementPeriod) },
        timeFrom: { $0.timeFrom },
        timeTo: { $0.timeTo },
        quantity: { $0.quantity }
    )
}

private func aggregate<Entry>(
    _ entries: [Entry],
    key: (Entry) -> SettlementKey,
    timeFrom: (Entry) -> String,
    timeTo: (Entry) -> String,
    quantity: (Entry) -> Double
) -> [GraphPoint] {
    if entries.isEmpty { return [] }
    let seriesId = "SOFIA_TOTAL"
    var order: [SettlementKey] = []
    var groups: [SettlementKey: [Entry]] = [:]
    for entry in entries {
        let groupKey = key(entry)
        if groups[groupKey] == nil {
            order.append(groupKey)
            groups[groupKey] = [entry]
        } else {
            groups[groupKey]?.append(entry)
        }
    }
    var points: [GraphPoint] = []
    points.reserveCapacity(order.count)
    for groupKey in order {
        guard let grouped = groups[groupKey], let first = grouped.first,
              let from = ApiTime.parseUtc(timeFrom(first)),
              let to = ApiTime.parseUtc(timeTo(first))
        else { continue }
        let total = grouped.reduce(0.0) { $0 + quantity($1) }
        points.append(GraphPoint(id: seriesId, timeFrom: from, timeTo: to, quantity: total))
    }
    return points.sorted { $0.timeFrom < $1.timeFrom }
}

/// `List<WeatherEntryDto>.toGraphPoint()`
public func weatherGraphPoints(_ entries: [WeatherEntryDto]) -> [GraphPoint] {
    entries.compactMap { dto -> GraphPoint? in
        guard let from = ApiTime.parseUtc(dto.timeFrom), let to = ApiTime.parseUtc(dto.timeTo) else { return nil }
        return GraphPoint(id: "WEATHER", timeFrom: from, timeTo: to, quantity: dto.windSpeed)
    }
    .sorted { $0.timeFrom < $1.timeFrom }
}

/// `List<MelEntryDto>.toMelPoints()` : une série déjà sommée par le serveur.
public func melGraphPoints(_ entries: [MelEntryDto]) -> [GraphPoint] {
    let seriesId = "SOFIA_TOTAL"
    return entries.compactMap { dto -> GraphPoint? in
        guard let from = ApiTime.parseUtc(dto.timeFrom), let to = ApiTime.parseUtc(dto.timeTo) else { return nil }
        return GraphPoint(id: seriesId, timeFrom: from, timeTo: to, quantity: dto.levelMw)
    }
    .sorted { $0.timeFrom < $1.timeFrom }
}

/// `calculateTopProduction` / `calculateTopB1610` : maxima sur tout l'historique, 7, 30 et 90 jours.
public func calculateTopWindows(_ points: [GraphPoint], now: Date = Date()) -> TopWindows {
    if points.isEmpty { return .empty }

    func findMax(_ filtered: [GraphPoint]) -> TopPoint {
        let maxPoint = filtered.max { $0.quantity < $1.quantity }
        return TopPoint(maxQuantity: maxPoint?.quantity ?? 0, maxDate: maxPoint?.timeFrom)
    }

    let last7Days = points.filter { $0.timeFrom >= now.addingTimeInterval(-7 * 86_400) }
    let last30Days = points.filter { $0.timeFrom >= now.addingTimeInterval(-30 * 86_400) }
    let last90Days = points.filter { $0.timeFrom >= now.addingTimeInterval(-90 * 86_400) }

    return TopWindows(
        allTime: findMax(points),
        last7Days: findMax(last7Days),
        last30Days: findMax(last30Days),
        last90Days: findMax(last90Days)
    )
}

/// `B1610TopProductionWindowsDto.toTopWindows()`
public func topWindows(from dto: B1610TopProductionWindowsDto) -> TopWindows {
    func point(_ value: B1610TopProductionPointDto) -> TopPoint {
        TopPoint(maxQuantity: value.quantity, maxDate: ApiTime.parseInstant(value.maxDate))
    }
    return TopWindows(
        allTime: point(dto.allTime),
        last7Days: point(dto.last7Days),
        last30Days: point(dto.last30Days),
        last90Days: point(dto.last90Days)
    )
}

/// `RemitEntryDto.toEntity().toModel()`
public func remitNotice(from dto: RemitEntryDto) -> RemitNotice {
    RemitNotice(
        id: dto.id,
        mrid: dto.mrid,
        revisionNumber: dto.revisionNumber,
        bmuId: dto.bmuId,
        participantId: dto.participantId,
        assetId: dto.assetId,
        unavailabilityType: dto.unavailabilityType,
        eventType: dto.eventType,
        messageHeading: dto.messageHeading,
        fuelType: dto.fuelType,
        normalCapacityMw: dto.normalCapacityMw,
        availableCapacityMw: dto.availableCapacityMw,
        unavailableCapacityMw: dto.unavailableCapacityMw,
        eventStatus: dto.eventStatus,
        eventStartTime: ApiTime.parseInstant(dto.eventStartTime),
        eventEndTime: ApiTime.parseInstant(dto.eventEndTime),
        cause: dto.cause,
        relatedInformation: dto.relatedInformation,
        publishTime: ApiTime.parseInstant(dto.publishTime),
        outageProfile: dto.outageProfile
    )
}

/// Supprime les doublons par id en gardant la première occurrence (`distinctBy { it.id }`).
public func distinctRemits(_ entries: [RemitEntryDto]) -> [RemitEntryDto] {
    var seen = Set<Int>()
    return entries.filter { seen.insert($0.id).inserted }
}

/// Ordre de la requête Room : `ORDER BY publishTime DESC` (les dates absentes en dernier).
public func sortedByPublishTimeDescending(_ notices: [RemitNotice]) -> [RemitNotice] {
    notices.sorted { lhs, rhs in
        switch (lhs.publishTime, rhs.publishTime) {
        case let (left?, right?): return left > right
        case (.some, .none): return true
        default: return false
        }
    }
}

/// Exécute les appels en parallèle et renvoie les résultats dans l'ordre d'entrée (comme `awaitAll()`).
func concurrentMap<Input: Sendable, Output: Sendable>(
    _ inputs: [Input],
    _ transform: @escaping @Sendable (Input) async throws -> Output
) async throws -> [Output] {
    try await withThrowingTaskGroup(of: (Int, Output).self) { group in
        for (index, input) in inputs.enumerated() {
            group.addTask {
                let output = try await transform(input)
                return (index, output)
            }
        }
        var results = [Output?](repeating: nil, count: inputs.count)
        for try await pair in group {
            results[pair.0] = pair.1
        }
        return results.compactMap { $0 }
    }
}

public struct SofiaTimeoutError: Error, Sendable {}

/// Équivalent de `withTimeout` (coroutines).
func withTimeout<Output: Sendable>(
    seconds: Double,
    _ operation: @escaping @Sendable () async throws -> Output
) async throws -> Output {
    try await withThrowingTaskGroup(of: Output.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw SofiaTimeoutError()
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else { throw SofiaTimeoutError() }
        return result
    }
}
