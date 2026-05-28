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
        case .test:   return 1400
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

// MARK: - REMIT

public struct RemitResponse: Codable, Identifiable {
    public let id: Int
    public let mrid: String
    public let revisionNumber: Int
    public let bmuId: String
    public let participantId: String
    public let assetId: String
    public let unavailabilityType: String
    public let eventType: String
    public let messageHeading: String
    public let fuelType: String
    public let normalCapacityMw: Double?
    public let availableCapacityMw: Double?
    public let unavailableCapacityMw: Double?
    public let eventStatus: String
    public let eventStartTime: Date?
    public let eventEndTime: Date?
    public let cause: String
    public let relatedInformation: String
    public let publishTime: Date?
    public let outageProfile: String

    enum CodingKeys: String, CodingKey {
        case id
        case mrid
        case revisionNumber        = "revision_number"
        case bmuId                 = "bmu_id"
        case participantId         = "participant_id"
        case assetId               = "asset_id"
        case unavailabilityType    = "unavailability_type"
        case eventType             = "event_type"
        case messageHeading        = "message_heading"
        case fuelType              = "fuel_type"
        case normalCapacityMw      = "normal_capacity_mw"
        case availableCapacityMw   = "available_capacity_mw"
        case unavailableCapacityMw = "unavailable_capacity_mw"
        case eventStatus           = "event_status"
        case eventStartTime        = "event_start_time"
        case eventEndTime          = "event_end_time"
        case cause
        case relatedInformation    = "related_information"
        case publishTime           = "publish_time"
        case outageProfile         = "outage_profile"
    }

    /// True when the event window overlaps the current moment.
    public var isCurrentlyActive: Bool {
        let now = Date()
        let start = eventStartTime ?? .distantPast
        let end   = eventEndTime   ?? .distantFuture
        return start <= now && now <= end
    }

    /// Capacity reduction described by this REMIT notice, if both fields are present.
    public var capacityReductionMw: Double? {
        guard let normal = normalCapacityMw,
              let available = availableCapacityMw else { return unavailableCapacityMw }
        return normal - available
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
// MARK: - Top Production (records)

public struct PnTopProductionPoint: Codable {
    public let maxMw: Double
    public let maxDate: Date?

    enum CodingKeys: String, CodingKey {
        case maxMw   = "max_mw"
        case maxDate = "max_date"
    }

    public init(maxMw: Double, maxDate: Date?) {
        self.maxMw   = maxMw
        self.maxDate = maxDate
    }
}

public struct PnTopProductionWindows: Codable {
    public let allTime:    PnTopProductionPoint
    public let last7Days:  PnTopProductionPoint
    public let last30Days: PnTopProductionPoint
    public let last90Days: PnTopProductionPoint

    enum CodingKeys: String, CodingKey {
        case allTime    = "all_time"
        case last7Days  = "last_7_days"
        case last30Days = "last_30_days"
        case last90Days = "last_90_days"
    }

    public init(allTime: PnTopProductionPoint,
                last7Days: PnTopProductionPoint,
                last30Days: PnTopProductionPoint,
                last90Days: PnTopProductionPoint) {
        self.allTime    = allTime
        self.last7Days  = last7Days
        self.last30Days = last30Days
        self.last90Days = last90Days
    }
}
