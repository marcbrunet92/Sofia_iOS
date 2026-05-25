import Foundation

// MARK: - BMU IDs
enum BMU: String, CaseIterable {
    case sofow11 = "T_SOFOW-11"
    case sofow12 = "T_SOFOW-12"
    case sofow21 = "T_SOFOW-21"
    case sofow22 = "T_SOFOW-22"
    case heym11  = "T_HEYM11"

    var displayName: String {
        switch self {
        case .sofow11: return "SOFOW-11"
        case .sofow12: return "SOFOW-12"
        case .sofow21: return "SOFOW-21"
        case .sofow22: return "SOFOW-22"
        case .heym11:  return "HEYM-11"
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
