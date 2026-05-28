import Foundation

// SofiaCore — PnResponse+Aggregation.swift
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

    func aggregatedHistory() -> [AggregatedPoint] {
        let buckets = reduce(into: [Date: Double]()) { result, point in
            result[point.timeFrom, default: 0] += point.levelMw
        }
        return buckets
            .map { AggregatedPoint(time: $0.key, totalMw: $0.value) }
            .sorted { $0.time < $1.time }
    }
}
