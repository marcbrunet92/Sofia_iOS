import Foundation

/// Cache local, équivalent de la base Room (`SofiaDatabase` + `SofiaDao`).
///
/// Chaque « table » est un fichier JSON remplacé en bloc à chaque rafraîchissement, comme les
/// méthodes `refresh…Points` du DAO (clear + insert dans une transaction). Si l'App Group
/// `group.com.lemarc.Sofia` est activé, le cache est partagé avec le widget.
public actor SofiaLocalStore {
    public static let shared = SofiaLocalStore()

    private let directory: URL?
    private var memory: [String: Any] = [:]

    public init(directory: URL? = SofiaLocalStore.defaultDirectory()) {
        self.directory = directory
    }

    /// Conteneur de l'App Group s'il est disponible, sinon Application Support de l'app (ou du widget).
    public static func defaultDirectory() -> URL? {
        let fileManager = FileManager.default
        let base = fileManager.containerURL(forSecurityApplicationGroupIdentifier: SofiaConstants.appGroupIdentifier)
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let base else { return nil }
        let directory = base.appendingPathComponent("SofiaCache", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    // MARK: - production_points

    public func productionPoints(testMode: Bool) -> [GraphPoint] {
        read([GraphPoint].self, "production_points_\(suffix(testMode))") ?? []
    }

    public func refreshProductionPoints(testMode: Bool, points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "production_points_\(suffix(testMode))")
    }

    // MARK: - b1610_points

    public func b1610Points(testMode: Bool) -> [GraphPoint] {
        read([GraphPoint].self, "b1610_points_\(suffix(testMode))") ?? []
    }

    public func refreshB1610Points(testMode: Bool, points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "b1610_points_\(suffix(testMode))")
    }

    // MARK: - weather_points

    public func weatherPoints() -> [GraphPoint] {
        read([GraphPoint].self, "weather_points") ?? []
    }

    public func refreshWeatherPoints(_ points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "weather_points")
    }

    // MARK: - remit_notices

    public func remitNotices(testMode: Bool) -> [RemitNotice] {
        read([RemitNotice].self, "remit_notices_\(suffix(testMode))") ?? []
    }

    public func refreshRemitNotices(testMode: Bool, notices: [RemitNotice]) {
        write(sortedByPublishTimeDescending(notices), "remit_notices_\(suffix(testMode))")
    }

    // MARK: - mel_points

    public func melPoints(testMode: Bool) -> [GraphPoint] {
        read([GraphPoint].self, "mel_points_\(suffix(testMode))") ?? []
    }

    public func refreshMelPoints(testMode: Bool, points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "mel_points_\(suffix(testMode))")
    }

    // MARK: - uou_days

    public func uouDays(testMode: Bool) -> [UouDay] {
        read([UouDay].self, "uou_days_\(suffix(testMode))") ?? []
    }

    public func refreshUouDays(testMode: Bool, days: [UouDay]) {
        write(days.sorted { $0.date < $1.date }, "uou_days_\(suffix(testMode))")
    }

    // MARK: - gb_context

    public func gbContext() -> GbContext? {
        read(GbContext.self, "gb_context")
    }

    public func refreshGbContext(_ context: GbContext) {
        write(context, "gb_context")
    }

    // MARK: - Fichiers

    private func suffix(_ testMode: Bool) -> String {
        testMode ? "test" : "live"
    }

    private func read<Value: Decodable>(_ type: Value.Type, _ name: String) -> Value? {
        if let cached = memory[name] as? Value { return cached }
        guard let url = directory?.appendingPathComponent("\(name).json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(Value.self, from: data)
        else { return nil }
        memory[name] = value
        return value
    }

    private func write<Value: Encodable>(_ value: Value, _ name: String) {
        memory[name] = value
        guard let url = directory?.appendingPathComponent("\(name).json"),
              let data = try? JSONEncoder().encode(value)
        else { return }
        try? data.write(to: url, options: .atomic)
    }
}
