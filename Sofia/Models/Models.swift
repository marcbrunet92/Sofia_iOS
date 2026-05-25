import Foundation

// MARK: - BMU Groups
enum AppMode {
    case normal   // Sofia farm: T_SOFOW-11/12/21/22 aggregated
    case test     // Test mode: only T_HEYM11

    var bmuIds: [String] {
        switch self {
        case .normal: return ["T_SOFOW-11", "T_SOFOW-12", "T_SOFOW-21", "T_SOFOW-22"]
        case .test:   return ["T_HEYM11"]
        }
    }

    var capacityMW: Double {
        switch self {
        case .normal: return 1400
        case .test:   return 1400  // HEYM11 rated capacity
        }
    }

    var displayName: String {
        switch self {
        case .normal: return "Sofia Wind Farm"
        case .test:   return "Test Mode (HEYM11)"
        }
    }
}

// MARK: - API Models
struct PnResponse: Codable, Identifiable {
    var id: String { "\(bmuId)-\(timeFrom)" }
    let bmuId: String
    let timeFrom: Date
    let timeTo: Date
    let settlementPeriod: Int
    let levelMw: Double
    let source: String?

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case settlementPeriod = "settlement_period"
        case levelMw = "level_mw"
        case source
    }
}

struct PnLatestSettlementPeriod: Codable {
    let bmuId: String
    let settlementPeriod: Int?
    let timeFrom: Date?

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case settlementPeriod = "settlement_period"
        case timeFrom = "time_from"
    }
}

struct PnDateRange: Codable {
    let oldest: Date?
    let latest: Date?
}

// MARK: - Aggregated point for the chart
struct AggregatedPoint: Identifiable {
    let id = UUID()
    let time: Date
    let totalMw: Double
}
