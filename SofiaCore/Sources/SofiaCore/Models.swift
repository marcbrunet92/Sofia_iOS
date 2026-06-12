import Foundation
import FoundationNetworking

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

    /// Identifier used to tag aggregated points for this mode.
    public var aggregatedId: String {
        switch self {
        case .normal: return "SOFIA_TOTAL"
        case .test:   return bmuIds[0]
        }
    }
}

// MARK: - Shared constants

public enum SofiaConstants {
    /// Start of the history window requested from the API.
    /// Equivalent to Android's HISTORY_START.
    public static let historyStart: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }()
}

// MARK: - Time window filtering

/// Equivalent of Android's TimeWindow enum.
public enum TimeWindow {
    case all
    case last24h
    case last7Days
    case last30Days
    case last90Days

    /// Duration to look back from the latest point, or nil for no filtering (all data).
    public var duration: TimeInterval? {
        switch self {
        case .all:       return nil
        case .last24h:   return 24 * 60 * 60
        case .last7Days: return 7 * 24 * 60 * 60
        case .last30Days: return 30 * 24 * 60 * 60
        case .last90Days: return 90 * 24 * 60 * 60
        }
    }
}

// MARK: - Generic graph point

/// Generic point used for charts after aggregation (production, B1610, weather).
public struct GraphPoint: Identifiable, Codable, Equatable {
    public var id: String { "\(seriesId)-\(timeFrom.timeIntervalSince1970)" }

    /// Series identifier (e.g. "SOFIA_TOTAL", a BMU id, or "WEATHER").
    public let seriesId: String
    public let timeFrom: Date
    public let timeTo: Date
    public let quantity: Double

    public init(seriesId: String, timeFrom: Date, timeTo: Date, quantity: Double) {
        self.seriesId = seriesId
        self.timeFrom = timeFrom
        self.timeTo = timeTo
        self.quantity = quantity
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

// MARK: - B1610

public struct B1610Response: Codable, Identifiable {
    public var id: String { "\(bmuId)-\(timeFrom)" }
    public let bmuId: String
    public let timeFrom: Date
    public let timeTo: Date
    public let quantity: Double
    public let settlementPeriod: Int

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case quantity
        case settlementPeriod = "settlement_period"
    }

    public init(bmuId: String, timeFrom: Date, timeTo: Date, quantity: Double, settlementPeriod: Int) {
        self.bmuId = bmuId
        self.timeFrom = timeFrom
        self.timeTo = timeTo
        self.quantity = quantity
        self.settlementPeriod = settlementPeriod
    }
}

// MARK: - Weather

public struct WeatherResponse: Codable, Identifiable {
    public var id: String { "WEATHER-\(timeFrom)" }
    public let timeFrom: Date
    public let timeTo: Date
    public let windSpeed: Double
    public let source: String?

    enum CodingKeys: String, CodingKey {
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case windSpeed = "wind_speed"
        case source
    }

    public init(timeFrom: Date, timeTo: Date, windSpeed: Double, source: String?) {
        self.timeFrom = timeFrom
        self.timeTo = timeTo
        self.windSpeed = windSpeed
        self.source = source
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

    public init(
        id: Int,
        mrid: String,
        revisionNumber: Int,
        bmuId: String,
        participantId: String,
        assetId: String,
        unavailabilityType: String,
        eventType: String,
        messageHeading: String,
        fuelType: String,
        normalCapacityMw: Double?,
        availableCapacityMw: Double?,
        unavailableCapacityMw: Double?,
        eventStatus: String,
        eventStartTime: Date?,
        eventEndTime: Date?,
        cause: String,
        relatedInformation: String,
        publishTime: Date?,
        outageProfile: String
    ) {
        self.id = id
        self.mrid = mrid
        self.revisionNumber = revisionNumber
        self.bmuId = bmuId
        self.participantId = participantId
        self.assetId = assetId
        self.unavailabilityType = unavailabilityType
        self.eventType = eventType
        self.messageHeading = messageHeading
        self.fuelType = fuelType
        self.normalCapacityMw = normalCapacityMw
        self.availableCapacityMw = availableCapacityMw
        self.unavailableCapacityMw = unavailableCapacityMw
        self.eventStatus = eventStatus
        self.eventStartTime = eventStartTime
        self.eventEndTime = eventEndTime
        self.cause = cause
        self.relatedInformation = relatedInformation
        self.publishTime = publishTime
        self.outageProfile = outageProfile
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

// MARK: - Aggregated point for the chart (legacy, kept for compatibility)

public struct AggregatedPoint: Identifiable {
    public let id = UUID()
    public let time: Date
    public let totalMw: Double

    public init(time: Date, totalMw: Double) {
        self.time = time
        self.totalMw = totalMw
    }
}

// MARK: - Top Production (records), generic

/// Generic single record point: a max quantity reached at a given date.
public struct TopPoint: Codable, Equatable {
    public let maxQuantity: Double
    public let maxDate: Date?

    public init(maxQuantity: Double, maxDate: Date?) {
        self.maxQuantity = maxQuantity
        self.maxDate = maxDate
    }

    public static let empty = TopPoint(maxQuantity: 0.0, maxDate: nil)
}

/// Generic all-time / 7d / 30d / 90d records, used for both PN and B1610.
public struct TopWindows: Codable, Equatable {
    public let allTime: TopPoint
    public let last7Days: TopPoint
    public let last30Days: TopPoint
    public let last90Days: TopPoint

    public init(allTime: TopPoint, last7Days: TopPoint, last30Days: TopPoint, last90Days: TopPoint) {
        self.allTime = allTime
        self.last7Days = last7Days
        self.last30Days = last30Days
        self.last90Days = last90Days
    }

    public static let empty = TopWindows(
        allTime: .empty,
        last7Days: .empty,
        last30Days: .empty,
        last90Days: .empty
    )
}

// MARK: - Raw DTOs for top-production endpoints (PN)

public struct PnTopProductionPointDto: Codable {
    public let maxMw: Double
    public let maxDate: Date?

    enum CodingKeys: String, CodingKey {
        case maxMw   = "max_mw"
        case maxDate = "max_date"
    }

    public init(maxMw: Double, maxDate: Date?) {
        self.maxMw = maxMw
        self.maxDate = maxDate
    }

    public func toTopPoint() -> TopPoint {
        TopPoint(maxQuantity: maxMw, maxDate: maxDate)
    }
}

public struct PnTopProductionWindowsDto: Codable {
    public let allTime: PnTopProductionPointDto
    public let last7Days: PnTopProductionPointDto
    public let last30Days: PnTopProductionPointDto
    public let last90Days: PnTopProductionPointDto

    enum CodingKeys: String, CodingKey {
        case allTime    = "all_time"
        case last7Days  = "last_7_days"
        case last30Days = "last_30_days"
        case last90Days = "last_90_days"
    }

    public init(allTime: PnTopProductionPointDto,
                last7Days: PnTopProductionPointDto,
                last30Days: PnTopProductionPointDto,
                last90Days: PnTopProductionPointDto) {
        self.allTime    = allTime
        self.last7Days  = last7Days
        self.last30Days = last30Days
        self.last90Days = last90Days
    }

    public func toTopWindows() -> TopWindows {
        TopWindows(
            allTime: allTime.toTopPoint(),
            last7Days: last7Days.toTopPoint(),
            last30Days: last30Days.toTopPoint(),
            last90Days: last90Days.toTopPoint()
        )
    }
}

// MARK: - Raw DTOs for top-production endpoints (B1610)

public struct B1610TopProductionPointDto: Codable {
    public let quantity: Double
    public let maxDate: Date?

    enum CodingKeys: String, CodingKey {
        case quantity
        case maxDate = "max_date"
    }

    public init(quantity: Double, maxDate: Date?) {
        self.quantity = quantity
        self.maxDate = maxDate
    }

    public func toTopPoint() -> TopPoint {
        TopPoint(maxQuantity: quantity, maxDate: maxDate)
    }
}

public struct B1610TopProductionWindowsDto: Codable {
    public let allTime: B1610TopProductionPointDto
    public let last7Days: B1610TopProductionPointDto
    public let last30Days: B1610TopProductionPointDto
    public let last90Days: B1610TopProductionPointDto

    enum CodingKeys: String, CodingKey {
        case allTime    = "all_time"
        case last7Days  = "last_7_days"
        case last30Days = "last_30_days"
        case last90Days = "last_90_days"
    }

    public init(allTime: B1610TopProductionPointDto,
                last7Days: B1610TopProductionPointDto,
                last30Days: B1610TopProductionPointDto,
                last90Days: B1610TopProductionPointDto) {
        self.allTime    = allTime
        self.last7Days  = last7Days
        self.last30Days = last30Days
        self.last90Days = last90Days
    }

    public func toTopWindows() -> TopWindows {
        TopWindows(
            allTime: allTime.toTopPoint(),
            last7Days: last7Days.toTopPoint(),
            last30Days: last30Days.toTopPoint(),
            last90Days: last90Days.toTopPoint()
        )
    }
}

// MARK: - Snapshots (mirroring Android's ProductionSnapshot / B1610Snapshot / WeatherSnapshot)

public struct ProductionSnapshot {
    public let points: [GraphPoint]
    public let currentMw: Double
    public let latestDataTimestamp: Date?
    public let topProduction: TopWindows

    public init(points: [GraphPoint], currentMw: Double, latestDataTimestamp: Date?, topProduction: TopWindows) {
        self.points = points
        self.currentMw = currentMw
        self.latestDataTimestamp = latestDataTimestamp
        self.topProduction = topProduction
    }
}

public struct B1610Snapshot {
    public let points: [GraphPoint]
    public let latestDataTimestamp: Date?
    public let topB1610: TopWindows

    public init(points: [GraphPoint], latestDataTimestamp: Date?, topB1610: TopWindows) {
        self.points = points
        self.latestDataTimestamp = latestDataTimestamp
        self.topB1610 = topB1610
    }
}

public struct WeatherSnapshot {
    public let points: [GraphPoint]
    public let latestWindSpeed: Double?
    public let latestDataTimestamp: Date?

    public init(points: [GraphPoint], latestWindSpeed: Double?, latestDataTimestamp: Date?) {
        self.points = points
        self.latestWindSpeed = latestWindSpeed
        self.latestDataTimestamp = latestDataTimestamp
    }
}