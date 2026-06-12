import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// SofiaCore — Snapshots.swift
//
// High-level helpers that fetch raw API data, aggregate it, and produce the
// snapshot types consumed by the app layer. These mirror the Kotlin
// repositories' `refresh*` + `observe*` logic, minus persistence (which stays
// in the app layer, e.g. SwiftData/CoreData).

public extension SofiaAPIService {

    // MARK: - Production

    /// Fetches and aggregates production data for the given mode over the full history window.
    func fetchProductionSnapshot(mode: AppMode, now: Date = Date()) async throws -> ProductionSnapshot {
        let bmuIds = mode.bmuIds

        var allEntries: [PnResponse] = []
        try await withThrowingTaskGroup(of: [PnResponse].self) { group in
            for bmuId in bmuIds {
                group.addTask {
                    try await self.pnData(bmuId: bmuId, from: SofiaConstants.historyStart, to: now)
                }
            }
            for try await entries in group {
                allEntries.append(contentsOf: entries)
            }
        }

        let points = allEntries.aggregatedProductionPoints(seriesId: mode.aggregatedId)

        let topProduction: TopWindows
        if let dto = try? await self.topProduction() {
            topProduction = dto.toTopWindows()
        } else {
            topProduction = calculateTopWindows(from: points, now: now)
        }

        return ProductionSnapshot(
            points: points,
            currentMw: points.last?.quantity ?? 0.0,
            latestDataTimestamp: points.last?.timeTo,
            topProduction: topProduction
        )
    }

    // MARK: - B1610

    /// Fetches and aggregates B1610 data for the given mode over the full history window.
    func fetchB1610Snapshot(mode: AppMode, now: Date = Date()) async throws -> B1610Snapshot {
        let bmuIds = mode.bmuIds

        var allEntries: [B1610Response] = []
        try await withThrowingTaskGroup(of: [B1610Response].self) { group in
            for bmuId in bmuIds {
                group.addTask {
                    try await self.b1610Data(bmuId: bmuId, from: SofiaConstants.historyStart, to: now)
                }
            }
            for try await entries in group {
                allEntries.append(contentsOf: entries)
            }
        }

        let points = allEntries.aggregatedB1610Points(seriesId: mode.aggregatedId)

        let topB1610: TopWindows
        if let dto = try? await self.b1610TopProduction() {
            topB1610 = dto.toTopWindows()
        } else {
            topB1610 = calculateTopWindows(from: points, now: now)
        }

        return B1610Snapshot(
            points: points,
            latestDataTimestamp: points.last?.timeTo,
            topB1610: topB1610
        )
    }

    // MARK: - Weather

    /// Fetches weather data over the full history window.
    func fetchWeatherSnapshot(now: Date = Date()) async throws -> WeatherSnapshot {
        let entries = try await weatherData(from: SofiaConstants.historyStart, to: now)
        let points = entries.toGraphPoints()

        return WeatherSnapshot(
            points: points,
            latestWindSpeed: points.last?.quantity,
            latestDataTimestamp: points.last?.timeTo
        )
    }

    // MARK: - REMIT

    /// Fetches active REMIT notices for all BMUs of the given mode, deduplicated and
    /// sorted by publish time descending. Mirrors Android's `refreshRemits`.
    func fetchRemitNotices(mode: AppMode) async throws -> [RemitResponse] {
        let bmuIds = mode.bmuIds

        var allNotices: [RemitResponse] = []
        try await withThrowingTaskGroup(of: [RemitResponse].self) { group in
            for bmuId in bmuIds {
                group.addTask {
                    try await self.listRemits(bmuId: bmuId, eventStatus: "Active", limit: 100, offset: 0)
                }
            }
            for try await notices in group {
                allNotices.append(contentsOf: notices)
            }
        }

        var seen = Set<Int>()
        let deduped = allNotices.filter { seen.insert($0.id).inserted }

        return deduped.sorted { lhs, rhs in
            let lhsDate = lhs.publishTime ?? .distantPast
            let rhsDate = rhs.publishTime ?? .distantPast
            return lhsDate > rhsDate
        }
    }
}