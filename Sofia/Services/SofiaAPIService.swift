import Foundation

enum APIError: LocalizedError {
    case badURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .badURL:                  return "Invalid URL"
        case .networkError(let e):     return "Network error: \(e.localizedDescription)"
        case .decodingError(let e):    return "Decoding error: \(e.localizedDescription)"
        case .serverError(let code):   return "Server error: HTTP \(code)"
        }
    }
}

actor SofiaAPIService {
    static let shared = SofiaAPIService()

    private let baseURL = "https://sofia.lemarc.fr"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // Essai 1 : avec timezone (ex: "2026-05-24T00:00:00Z")
            let withTZ = ISO8601DateFormatter()
            withTZ.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withTZ.date(from: str) { return date }

            let withTZNoFrac = ISO8601DateFormatter()
            withTZNoFrac.formatOptions = [.withInternetDateTime]
            if let date = withTZNoFrac.date(from: str) { return date }

            // Essai 2 : SANS timezone (ex: "2026-05-24T00:00:00") → on suppose UTC
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

    // MARK: - Latest settlement period for a BMU
    func latestSettlement(for bmuId: String) async throws -> PnLatestSettlementPeriod {
        var components = URLComponents(string: "\(baseURL)/pn/latest-settlement-period")!
        components.queryItems = [URLQueryItem(name: "bmu_id", value: bmuId)]
        guard let url = components.url else { throw APIError.badURL }
        return try await fetch(url: url)
    }

    // MARK: - PN data for a BMU over a time range
    func pnData(bmuId: String, from: Date, to: Date) async throws -> [PnResponse] {
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

    // MARK: - Date range of available data
    func dateRange() async throws -> PnDateRange {
        guard let url = URL(string: "\(baseURL)/pn/date-range") else { throw APIError.badURL }
        return try await fetch(url: url)
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
