import Foundation

// MARK: - BMU Groups
public enum AppMode {
    case normal   // Sofia farm: T_SOFOW-11/12/21/22 aggregated
    case test     // Test mode: only T_HEYM11

    public var bmuIds: [String] {
        switch self {
        case .normal: return ["T_SOFOW-11", "T_SOFOW-12", "T_SOFOW-21", "T_SOFOW-22"]
        case .test:   return ["T_HEYM11"]
        }
    }

    public var capacityMW: Double {
        switch self {
        case .normal: return 1400
        case .test:   return 1400  // HEYM11 rated capacity
        }
    }

    public var displayName: String {
        switch self {
        case .normal: return "Sofia Wind Farm"
        case .test:   return "Test Mode (HEYM11)"
        }
    }
}

// MARK: - API Models
public struct PnResponse: Codable, Identifiable {
    public var id: String { "\(bmuId)-\(timeFrom)" }
    public let bmuId: String
    public let timeFrom: Date
    public let timeTo: Date
    public let settlementPeriod: Int
    public let levelMw: Double
    public let source: String?

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case settlementPeriod = "settlement_period"
        case levelMw = "level_mw"
        case source
    }

    public init(bmuId: String, timeFrom: Date, timeTo: Date, settlementPeriod: Int, levelMw: Double, source: String?) {
        self.bmuId = bmuId
        self.timeFrom = timeFrom
        self.timeTo = timeTo
        self.settlementPeriod = settlementPeriod
        self.levelMw = levelMw
        self.source = source
    }
}

public struct PnLatestSettlementPeriod: Codable {
    public let bmuId: String
    public let settlementPeriod: Int?
    public let timeFrom: Date?

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case settlementPeriod = "settlement_period"
        case timeFrom = "time_from"
    }

    public init(bmuId: String, settlementPeriod: Int?, timeFrom: Date?) {
        self.bmuId = bmuId
        self.settlementPeriod = settlementPeriod
        self.timeFrom = timeFrom
    }
}

public struct PnDateRange: Codable {
    public let oldest: Date?
    public let latest: Date?

    public init(oldest: Date?, latest: Date?) {
        self.oldest = oldest
        self.latest = latest
    }
}

// MARK: - Aggregated point for the chart
public struct AggregatedPoint: Identifiable {
    public let id = UUID()
    public let time: Date
    public let totalMw: Double

    public init(time: Date, totalMw: Double) {
        self.time = time
        self.totalMw = totalMw
    }
}
