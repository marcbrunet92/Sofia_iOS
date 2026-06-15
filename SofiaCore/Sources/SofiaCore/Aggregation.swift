import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// SofiaCore — Aggregation.swift

/// Grouping key shared by production and B1610 aggregation: entries that share
/// the same settlement window are summed together.
private struct AggregationGroupKey: Hashable {
    let timeFrom: Date
    let timeTo: Date
    let settlementPeriod: Int
}

// MARK: - PnResponse aggregation (production)

public extension Array where Element == PnResponse {

    func latestPerBMU() -> [String: PnResponse] {
        reduce(into: [:]) { result, point in
            if let existing = result[point.bmuId] {
                if point.timeFrom > existing.timeFrom { result[point.bmuId] = point }
            } else {
                result[point.bmuId] = point
            }
        }
    }

    /// Legacy helper kept for compatibility: aggregates by timeFrom only.
    /// Prefer `aggregatedProductionPoints(seriesId:)` which groups by
    /// (timeFrom, timeTo, settlementPeriod) like the Android implementation.

    /// Aggregates production entries across BMUs into a single series of GraphPoints,
    /// summing levelMw for entries sharing the same (timeFrom, timeTo, settlementPeriod).
    /// Mirrors Android's `aggregateProduction`.
    func aggregatedProductionPoints(seriesId: String) -> [GraphPoint] {
        guard !isEmpty else { return [] }

        let grouped = Dictionary(grouping: self) { entry in
            AggregationGroupKey(timeFrom: entry.timeFrom, timeTo: entry.timeTo, settlementPeriod: entry.settlementPeriod)
        }

        return grouped.map { key, entries -> GraphPoint in
            let total = entries.reduce(0.0) { $0 + $1.levelMw }
            return GraphPoint(
                seriesId: seriesId,
                timeFrom: key.timeFrom,
                timeTo: key.timeTo,
                quantity: total
            )
        }
        .sorted { $0.timeFrom < $1.timeFrom }
    }
}

// MARK: - B1610Response aggregation

public extension Array where Element == B1610Response {

    /// Aggregates B1610 entries across BMUs into a single series of GraphPoints,
    /// summing quantity for entries sharing the same (timeFrom, timeTo, settlementPeriod).
    /// Mirrors Android's `aggregateB1610`.
    func aggregatedB1610Points(seriesId: String) -> [GraphPoint] {
        guard !isEmpty else { return [] }

        let grouped = Dictionary(grouping: self) { entry in
            AggregationGroupKey(timeFrom: entry.timeFrom, timeTo: entry.timeTo, settlementPeriod: entry.settlementPeriod)
        }

        return grouped.map { key, entries -> GraphPoint in
            let total = entries.reduce(0.0) { $0 + $1.quantity }
            return GraphPoint(
                seriesId: seriesId,
                timeFrom: key.timeFrom,
                timeTo: key.timeTo,
                quantity: total
            )
        }
        .sorted { $0.timeFrom < $1.timeFrom }
    }
}

// MARK: - WeatherResponse mapping

public extension Array where Element == WeatherResponse {

    /// Maps raw weather entries to GraphPoints, tagged with the "WEATHER" series id.
    /// Mirrors Android's `toGraphPoint` for weather.
    func toGraphPoints() -> [GraphPoint] {
        map { entry in
            GraphPoint(
                seriesId: "WEATHER",
                timeFrom: entry.timeFrom,
                timeTo: entry.timeTo,
                quantity: entry.windSpeed
            )
        }
        .sorted { $0.timeFrom < $1.timeFrom }
    }
}

// MARK: - Top windows calculation (records over 7/30/90 days and all-time)

/// Computes all-time / 7d / 30d / 90d records (max quantity + date reached) from a list
/// of GraphPoints. Mirrors Android's `calculateTopProduction` / `calculateTopB1610`,
/// which are identical aside from the input type.
public func calculateTopWindows(from points: [GraphPoint], now: Date = Date()) -> TopWindows {
    guard !points.isEmpty else { return .empty }

    func findMax(_ filtered: [GraphPoint]) -> TopPoint {
        guard let maxPoint = filtered.max(by: { $0.quantity < $1.quantity }) else {
            return .empty
        }
        return TopPoint(maxQuantity: maxPoint.quantity, maxDate: maxPoint.timeFrom)
    }

    let day: TimeInterval = 24 * 60 * 60
    let last7Days = points.filter { $0.timeFrom >= now.addingTimeInterval(-7 * day) }
    let last30Days = points.filter { $0.timeFrom >= now.addingTimeInterval(-30 * day) }
    let last90Days = points.filter { $0.timeFrom >= now.addingTimeInterval(-90 * day) }

    return TopWindows(
        allTime: findMax(points),
        last7Days: findMax(last7Days),
        last30Days: findMax(last30Days),
        last90Days: findMax(last90Days)
    )
}

// MARK: - Time window filtering (mirrors Android's filterPoints / utils.kt)

/// Filters a list of GraphPoints to those within `window` of the latest point's `timeTo`.
/// Returns all points unchanged for `.all`, and an empty array if `points` is empty
/// (and the window is not `.all`).
public func filterPoints(_ points: [GraphPoint], window: TimeWindow) -> [GraphPoint] {
    guard let duration = window.duration else { return points }
    guard let lastTimestamp = points.last?.timeTo else { return [] }
    let threshold = lastTimestamp.addingTimeInterval(-duration)
    return points.filter { $0.timeTo >= threshold }
}
