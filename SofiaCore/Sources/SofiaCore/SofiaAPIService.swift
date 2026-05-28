import Foundation

public enum APIError: LocalizedError {
    case badURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    public var errorDescription: String? {
        switch self {
        case .badURL:                  return "Invalid URL"
        case .networkError(let e):     return "Network error: \(e.localizedDescription)"
        case .decodingError(let e):    return "Decoding error: \(e.localizedDescription)"
        case .serverError(let code):   return "Server error: HTTP \(code)"
        }
    }
}

public actor SofiaAPIService {
    public static let shared = SofiaAPIService()

    public let baseURL = "https://sofia.lemarc.fr"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            let withTZ = ISO8601DateFormatter()
            withTZ.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withTZ.date(from: str) { return date }

            let withTZNoFrac = ISO8601DateFormatter()
            withTZNoFrac.formatOptions = [.withInternetDateTime]
            if let date = withTZNoFrac.date(from: str) { return date }

            let noTZ = DateFormatter()
            noTZ.locale = Locale(identifier: "en_US_POSIX")
            noTZ.timeZone = TimeZone(identifier: "UTC")
            noTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = noTZ.date(from: str) { return date }

            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Cannot parse date: \(str)")
        }
        return d
    }()

    public init() {}

    // MARK: - PN: data for a BMU over a time range

    public func pnData(bmuId: String, from: Date, to: Date) async throws -> [PnResponse] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        var components = URLComponents(string: "\(baseURL)/pn/\(bmuId)")!
        components.queryItems = [
            URLQueryItem(name: "time_from", value: fmt.string(from: from)),
            URLQueryItem(name: "time_to",   value: fmt.string(from: to))
        ]
        guard let url = components.url else { throw APIError.badURL }
        return try await fetch(url: url)
    }

    // MARK: - PN: latest settlement period for a BMU

    public func latestSettlement(for bmuId: String) async throws -> PnLatestSettlementPeriod {
        var components = URLComponents(string: "\(baseURL)/pn/latest-settlement-period")!
        components.queryItems = [URLQueryItem(name: "bmu_id", value: bmuId)]
        guard let url = components.url else { throw APIError.badURL }
        return try await fetch(url: url)
    }
    // MARK: - PN: date range available in the database

    public func pnDateRange() async throws -> PnDateRange {
        guard let url = URL(string: "\(baseURL)/pn/date-range") else {
            throw APIError.badURL
        }
        return try await fetch(url: url)
    }

    // MARK: - PN: all-time / 7d / 30d / 90d production records

    public func topProduction() async throws -> PnTopProductionWindows {
        guard let url = URL(string: "\(baseURL)/pn/top-production") else {
            throw APIError.badURL
        }
        return try await fetch(url: url)
    }
    // MARK: - REMIT: list with optional filters

    /// Fetches a paginated list of REMIT notices.
    /// - Parameters:
    ///   - bmuId: Filter to a specific BMU (pass `nil` for all).
    ///   - eventStatus: e.g. `"Active"`, `"Dismissed"` (pass `nil` for all).
    ///   - limit: Page size (max 500, default 100).
    ///   - offset: Pagination offset (default 0).
    public func listRemits(
        bmuId: String?       = nil,
        eventStatus: String? = nil,
        limit: Int           = 100,
        offset: Int          = 0
    ) async throws -> [RemitResponse] {
        var components = URLComponents(string: "\(baseURL)/remit")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "limit",  value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        if let bmuId       { items.append(URLQueryItem(name: "bmu_id",       value: bmuId)) }
        if let eventStatus { items.append(URLQueryItem(name: "event_status", value: eventStatus)) }
        components.queryItems = items
        guard let url = components.url else { throw APIError.badURL }
        return try await fetch(url: url)
    }

    // MARK: - REMIT: currently active notices for a BMU

    public func activeRemits(for bmuId: String) async throws -> [RemitResponse] {
        guard let url = URL(string: "\(baseURL)/remit/active/\(bmuId)") else {
            throw APIError.badURL
        }
        return try await fetch(url: url)
    }

    // MARK: - REMIT: single notice by ID

    public func remit(id: Int) async throws -> RemitResponse {
        guard let url = URL(string: "\(baseURL)/remit/\(id)") else {
            throw APIError.badURL
        }
        return try await fetch(url: url)
    }

    // MARK: - REMIT: force refresh from Elexon

    /// Triggers an immediate re-fetch of all active REMIT records from the Elexon API.
    /// Returns the raw server response (number of persisted records, etc.).
    @discardableResult
    public func refreshRemits() async throws -> Data {
        guard let url = URL(string: "\(baseURL)/remit/refresh") else {
            throw APIError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(http.statusCode)
        }
        return data
    }

    // MARK: - Generic fetch + decode

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw APIError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
