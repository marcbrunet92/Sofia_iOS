import Foundation

/// DTO de l'API, équivalents des data classes de data/api/SofiaApiService.kt.
///
/// Le décodage est tolérant (champ absent ou `null` → valeur par défaut) pour qu'un seul
/// enregistrement incomplet ne fasse pas échouer tout un rafraîchissement.

public struct PnEntryDto: Decodable, Sendable {
    public let bmuId: String
    public let timeFrom: String
    public let timeTo: String
    public let settlementPeriod: Int
    public let levelMw: Double
    public let source: String

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case settlementPeriod = "settlement_period"
        case levelMw = "level_mw"
        case source
    }
}

extension PnEntryDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bmuId = try container.decodeIfPresent(String.self, forKey: .bmuId) ?? ""
        timeFrom = try container.decode(String.self, forKey: .timeFrom)
        timeTo = try container.decode(String.self, forKey: .timeTo)
        settlementPeriod = try container.decodeIfPresent(Int.self, forKey: .settlementPeriod) ?? 0
        levelMw = try container.decodeIfPresent(Double.self, forKey: .levelMw) ?? 0
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
    }
}

public struct B1610EntryDto: Decodable, Sendable {
    public let bmuId: String
    public let timeFrom: String
    public let timeTo: String
    public let quantity: Double
    public let settlementPeriod: Int

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case quantity
        case settlementPeriod = "settlement_period"
    }
}

extension B1610EntryDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bmuId = try container.decodeIfPresent(String.self, forKey: .bmuId) ?? ""
        timeFrom = try container.decode(String.self, forKey: .timeFrom)
        timeTo = try container.decode(String.self, forKey: .timeTo)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 0
        settlementPeriod = try container.decodeIfPresent(Int.self, forKey: .settlementPeriod) ?? 0
    }
}

public struct B1610TopProductionPointDto: Decodable, Sendable {
    public let quantity: Double
    public let maxDate: String?

    enum CodingKeys: String, CodingKey {
        case quantity
        case maxDate = "max_date"
    }
}

extension B1610TopProductionPointDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 0
        maxDate = try container.decodeIfPresent(String.self, forKey: .maxDate)
    }
}

public struct B1610TopProductionWindowsDto: Decodable, Sendable {
    public let allTime: B1610TopProductionPointDto
    public let last7Days: B1610TopProductionPointDto
    public let last30Days: B1610TopProductionPointDto
    public let last90Days: B1610TopProductionPointDto

    enum CodingKeys: String, CodingKey {
        case allTime = "all_time"
        case last7Days = "last_7_days"
        case last30Days = "last_30_days"
        case last90Days = "last_90_days"
    }
}

public struct WeatherEntryDto: Decodable, Sendable {
    public let timeFrom: String
    public let timeTo: String
    public let windSpeed: Double
    public let source: String

    enum CodingKeys: String, CodingKey {
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case windSpeed = "wind_speed"
        case source
    }
}

extension WeatherEntryDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeFrom = try container.decode(String.self, forKey: .timeFrom)
        timeTo = try container.decode(String.self, forKey: .timeTo)
        windSpeed = try container.decodeIfPresent(Double.self, forKey: .windSpeed) ?? 0
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
    }
}

public struct RemitEntryDto: Decodable, Sendable {
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
    public let eventStartTime: String?
    public let eventEndTime: String?
    public let cause: String
    public let relatedInformation: String
    public let publishTime: String?
    public let outageProfile: String

    enum CodingKeys: String, CodingKey {
        case id
        case mrid
        case revisionNumber = "revision_number"
        case bmuId = "bmu_id"
        case participantId = "participant_id"
        case assetId = "asset_id"
        case unavailabilityType = "unavailability_type"
        case eventType = "event_type"
        case messageHeading = "message_heading"
        case fuelType = "fuel_type"
        case normalCapacityMw = "normal_capacity_mw"
        case availableCapacityMw = "available_capacity_mw"
        case unavailableCapacityMw = "unavailable_capacity_mw"
        case eventStatus = "event_status"
        case eventStartTime = "event_start_time"
        case eventEndTime = "event_end_time"
        case cause
        case relatedInformation = "related_information"
        case publishTime = "publish_time"
        case outageProfile = "outage_profile"
    }
}

extension RemitEntryDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        mrid = try container.decodeIfPresent(String.self, forKey: .mrid) ?? ""
        revisionNumber = try container.decodeIfPresent(Int.self, forKey: .revisionNumber) ?? 0
        bmuId = try container.decodeIfPresent(String.self, forKey: .bmuId) ?? ""
        participantId = try container.decodeIfPresent(String.self, forKey: .participantId) ?? ""
        assetId = try container.decodeIfPresent(String.self, forKey: .assetId) ?? ""
        unavailabilityType = try container.decodeIfPresent(String.self, forKey: .unavailabilityType) ?? ""
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType) ?? ""
        messageHeading = try container.decodeIfPresent(String.self, forKey: .messageHeading) ?? ""
        fuelType = try container.decodeIfPresent(String.self, forKey: .fuelType) ?? ""
        normalCapacityMw = try container.decodeIfPresent(Double.self, forKey: .normalCapacityMw)
        availableCapacityMw = try container.decodeIfPresent(Double.self, forKey: .availableCapacityMw)
        unavailableCapacityMw = try container.decodeIfPresent(Double.self, forKey: .unavailableCapacityMw)
        eventStatus = try container.decodeIfPresent(String.self, forKey: .eventStatus) ?? ""
        eventStartTime = try container.decodeIfPresent(String.self, forKey: .eventStartTime)
        eventEndTime = try container.decodeIfPresent(String.self, forKey: .eventEndTime)
        cause = try container.decodeIfPresent(String.self, forKey: .cause) ?? ""
        relatedInformation = try container.decodeIfPresent(String.self, forKey: .relatedInformation) ?? ""
        publishTime = try container.decodeIfPresent(String.self, forKey: .publishTime)
        outageProfile = try container.decodeIfPresent(String.self, forKey: .outageProfile) ?? ""
    }
}

/// MEL (Maximum Export Limit) : même forme que `PnEntryDto` (level_mw en MW).
public struct MelEntryDto: Decodable, Sendable {
    public let bmuId: String
    public let timeFrom: String
    public let timeTo: String
    public let settlementPeriod: Int
    public let levelMw: Double

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case timeFrom = "time_from"
        case timeTo = "time_to"
        case settlementPeriod = "settlement_period"
        case levelMw = "level_mw"
    }
}

extension MelEntryDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bmuId = try container.decodeIfPresent(String.self, forKey: .bmuId) ?? ""
        timeFrom = try container.decode(String.self, forKey: .timeFrom)
        timeTo = try container.decode(String.self, forKey: .timeTo)
        settlementPeriod = try container.decodeIfPresent(Int.self, forKey: .settlementPeriod) ?? 0
        levelMw = try container.decodeIfPresent(Double.self, forKey: .levelMw) ?? 0
    }
}

/// UOU2T14D : puissance utilisable prévue pour un jour (« yyyy-MM-dd »).
public struct UouEntryDto: Decodable, Sendable {
    public let bmuId: String
    public let forecastDate: String
    public let outputUsable: Double

    enum CodingKeys: String, CodingKey {
        case bmuId = "bmu_id"
        case forecastDate = "forecast_date"
        case outputUsable = "output_usable"
    }
}

extension UouEntryDto {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bmuId = try container.decodeIfPresent(String.self, forKey: .bmuId) ?? ""
        forecastDate = try container.decode(String.self, forKey: .forecastDate)
        outputUsable = try container.decodeIfPresent(Double.self, forKey: .outputUsable) ?? 0
    }
}

/// AGWS : dernière demi-heure publiée de l'éolien et du solaire de Grande-Bretagne (MW).
public struct AgwsLatestDto: Decodable, Sendable {
    public let timeFrom: String?
    public let windOffshoreMw: Double?
    public let windOnshoreMw: Double?
    public let solarMw: Double?

    enum CodingKeys: String, CodingKey {
        case timeFrom = "time_from"
        case windOffshoreMw = "wind_offshore_mw"
        case windOnshoreMw = "wind_onshore_mw"
        case solarMw = "solar_mw"
    }
}
