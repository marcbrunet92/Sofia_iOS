import Foundation

/// Équivalent de data/model/Model.kt.

public struct GraphPoint: Codable, Hashable, Sendable {
    public let id: String
    public let timeFrom: Date
    public let timeTo: Date
    public let quantity: Double

    public init(id: String, timeFrom: Date, timeTo: Date, quantity: Double) {
        self.id = id
        self.timeFrom = timeFrom
        self.timeTo = timeTo
        self.quantity = quantity
    }

    /// Équivalent de `copy(quantity = …)`.
    public func with(quantity: Double) -> GraphPoint {
        GraphPoint(id: id, timeFrom: timeFrom, timeTo: timeTo, quantity: quantity)
    }
}

public struct B1610Snapshot: Sendable {
    public let points: [GraphPoint]
    public let latestDataTimestamp: Date?
    public let topB1610: TopWindows
}

public struct WeatherSnapshot: Sendable {
    public let points: [GraphPoint]
    public let latestWindSpeed: Double?
    public let latestDataTimestamp: Date?
}

public struct ProductionSnapshot: Sendable {
    public let points: [GraphPoint]
    public let currentMw: Double
    public let latestDataTimestamp: Date?
    public let topProduction: TopWindows
}

public struct TopPoint: Codable, Hashable, Sendable {
    public let maxQuantity: Double
    public let maxDate: Date?

    public init(maxQuantity: Double, maxDate: Date?) {
        self.maxQuantity = maxQuantity
        self.maxDate = maxDate
    }
}

public struct TopWindows: Codable, Hashable, Sendable {
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
        allTime: TopPoint(maxQuantity: 0, maxDate: nil),
        last7Days: TopPoint(maxQuantity: 0, maxDate: nil),
        last30Days: TopPoint(maxQuantity: 0, maxDate: nil),
        last90Days: TopPoint(maxQuantity: 0, maxDate: nil)
    )
}

public struct RemitNotice: Codable, Hashable, Identifiable, Sendable {
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
}

extension String {
    /// Équivalent Kotlin de `isBlank()`.
    public var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Équivalent Kotlin de `ifBlank { fallback }`.
    public func ifBlank(_ fallback: String) -> String {
        isBlank ? fallback : self
    }
}
