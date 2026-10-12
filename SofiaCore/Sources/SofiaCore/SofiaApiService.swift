import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum SofiaApiError: Error, Sendable {
    case badURL(String)
    case http(Int)
}

/// Équivalent de l'interface Retrofit `SofiaApiService`.
public struct SofiaApiService: Sendable {
    public static let shared = SofiaApiService()

    private let baseURL: String
    private let session: URLSession

    public init(baseURL: String = SofiaConstants.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// GET pn/{bmuId}
    public func getProduction(bmuId: String, timeFrom: String, timeTo: String) async throws -> [PnEntryDto] {
        try await get("pn/\(bmuId)", query: [
            URLQueryItem(name: "time_from", value: timeFrom),
            URLQueryItem(name: "time_to", value: timeTo),
        ])
    }

    /// GET pn/total : somme des 4 unités Sofia calculée par le serveur (bmu_id « SOFIA_TOTAL »).
    public func getProductionTotal(timeFrom: String, timeTo: String) async throws -> [PnEntryDto] {
        try await get("pn/total", query: [
            URLQueryItem(name: "time_from", value: timeFrom),
            URLQueryItem(name: "time_to", value: timeTo),
        ])
    }

    /// PN du mode courant : la somme Sofia calculée par le serveur, ou l'unité de test.
    public func getProduction(testMode: Bool, timeFrom: String, timeTo: String) async throws -> [PnEntryDto] {
        if testMode {
            return try await getProduction(bmuId: SofiaConstants.testBmu, timeFrom: timeFrom, timeTo: timeTo)
        }
        return try await getProductionTotal(timeFrom: timeFrom, timeTo: timeTo)
    }

    /// GET remit
    public func getRemits(
        bmuId: String? = nil,
        eventStatus: String? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) async throws -> [RemitEntryDto] {
        var query: [URLQueryItem] = []
        if let bmuId { query.append(URLQueryItem(name: "bmu_id", value: bmuId)) }
        if let eventStatus { query.append(URLQueryItem(name: "event_status", value: eventStatus)) }
        query.append(URLQueryItem(name: "limit", value: String(limit)))
        query.append(URLQueryItem(name: "offset", value: String(offset)))
        return try await get("remit", query: query)
    }

    /// GET weather
    public func getWeather(timeFrom: String, timeTo: String) async throws -> [WeatherEntryDto] {
        try await get("weather", query: [
            URLQueryItem(name: "time_from", value: timeFrom),
            URLQueryItem(name: "time_to", value: timeTo),
        ])
    }

    /// GET b1610/{bmuId}
    public func getB1610(bmuId: String, timeFrom: String, timeTo: String) async throws -> [B1610EntryDto] {
        try await get("b1610/\(bmuId)", query: [
            URLQueryItem(name: "time_from", value: timeFrom),
            URLQueryItem(name: "time_to", value: timeTo),
        ])
    }

    /// GET b1610/total : somme des 4 unités Sofia calculée par le serveur (bmu_id « SOFIA_TOTAL »).
    public func getB1610Total(timeFrom: String, timeTo: String) async throws -> [B1610EntryDto] {
        try await get("b1610/total", query: [
            URLQueryItem(name: "time_from", value: timeFrom),
            URLQueryItem(name: "time_to", value: timeTo),
        ])
    }

    /// B1610 du mode courant : la somme Sofia calculée par le serveur, ou l'unité de test.
    public func getB1610(testMode: Bool, timeFrom: String, timeTo: String) async throws -> [B1610EntryDto] {
        if testMode {
            return try await getB1610(bmuId: SofiaConstants.testBmu, timeFrom: timeFrom, timeTo: timeTo)
        }
        return try await getB1610Total(timeFrom: timeFrom, timeTo: timeTo)
    }

    /// GET b1610/top-production
    public func getB1610TopProduction() async throws -> B1610TopProductionWindowsDto {
        try await get("b1610/top-production", query: [])
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw SofiaApiError.badURL(baseURL + path)
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw SofiaApiError.badURL(baseURL + path)
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SofiaApiError.http(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
