import Foundation

/// Cache local, équivalent de la base Room (`SofiaDatabase` + `SofiaDao`).
///
/// Chaque « table » est un fichier JSON remplacé en bloc à chaque rafraîchissement, comme les
/// méthodes `refresh…Points` du DAO (clear + insert dans une transaction). Si l'App Group
/// `group.com.lemarc.Sofia` est activé, le cache est partagé avec le widget.
public actor SofiaLocalStore {
    public static let shared = SofiaLocalStore()

    /// Version du cache, comme la version de la base Room. Si elle change, les tables sont
    /// supprimées au lieu d'être migrées : c'est un cache, le prochain rafraîchissement le remplit.
    /// v3 : plus de mode test, une seule série par table. v4 : comme la base Room v4.
    public static let version = 4

    private let directory: URL?
    private var memory: [String: Any] = [:]

    public init(directory: URL? = SofiaLocalStore.defaultDirectory()) {
        self.directory = directory
        if let directory {
            Self.dropTablesIfOutdated(in: directory)
        }
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

    public func productionPoints() -> [GraphPoint] {
        read([GraphPoint].self, "production_points") ?? []
    }

    public func refreshProductionPoints(_ points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "production_points")
    }

    // MARK: - b1610_points

    public func b1610Points() -> [GraphPoint] {
        read([GraphPoint].self, "b1610_points") ?? []
    }

    public func refreshB1610Points(_ points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "b1610_points")
    }

    // MARK: - weather_points

    public func weatherPoints() -> [GraphPoint] {
        read([GraphPoint].self, "weather_points") ?? []
    }

    public func refreshWeatherPoints(_ points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "weather_points")
    }

    // MARK: - remit_notices

    public func remitNotices() -> [RemitNotice] {
        read([RemitNotice].self, "remit_notices") ?? []
    }

    public func refreshRemitNotices(_ notices: [RemitNotice]) {
        write(sortedByPublishTimeDescending(notices), "remit_notices")
    }

    // MARK: - mel_points

    public func melPoints() -> [GraphPoint] {
        read([GraphPoint].self, "mel_points") ?? []
    }

    public func refreshMelPoints(_ points: [GraphPoint]) {
        write(points.sorted { $0.timeFrom < $1.timeFrom }, "mel_points")
    }

    // MARK: - uou_days

    public func uouDays() -> [UouDay] {
        read([UouDay].self, "uou_days") ?? []
    }

    public func refreshUouDays(_ days: [UouDay]) {
        write(days.sorted { $0.date < $1.date }, "uou_days")
    }

    // MARK: - gb_context

    public func gbContext() -> GbContext? {
        read(GbContext.self, "gb_context")
    }

    public func refreshGbContext(_ context: GbContext) {
        write(context, "gb_context")
    }

    // MARK: - Fichiers

    /// `fallbackToDestructiveMigration` : supprime les tables d'une version précédente du cache.
    /// Les instantanés des widgets (`widget_*.json`) ne sont pas des tables et sont conservés.
    private static func dropTablesIfOutdated(in directory: URL) {
        let marker = directory.appendingPathComponent("version")
        let stored = (try? String(contentsOf: marker, encoding: .utf8)).flatMap { Int($0) }
        guard stored != version else { return }
        let fileManager = FileManager.default
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "json" && !file.lastPathComponent.hasPrefix("widget_") {
            try? fileManager.removeItem(at: file)
        }
        try? String(version).write(to: marker, atomically: true, encoding: .utf8)
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
