import Foundation

/// Équivalent de widget/modern/SofiaWidgetSnapshots.kt.
///
/// Dernier jeu de données récupéré avec succès par un widget. Si un rafraîchissement échoue
/// (hors-ligne, app jamais ouverte donc cache vide…), le widget réaffiche ces données au lieu
/// de se vider.
public enum SofiaWidgetSnapshots {
    private static func file(_ name: String) -> URL? {
        SofiaLocalStore.defaultDirectory()?.appendingPathComponent("widget_\(name).json")
    }

    // MARK: - Live / graphique

    public static func saveLive(_ data: LiveData, name: String) {
        save(data, to: file(name))
    }

    public static func loadLive(name: String) -> LiveData? {
        guard var data = load(LiveData.self, from: file(name)) else { return nil }
        data.fromCache = true
        return data
    }

    // MARK: - Disponibilité par unité

    public static func saveUnits(_ data: UnitsData) {
        save(data, to: file("units"))
    }

    public static func loadUnits() -> UnitsData? {
        guard var data = load(UnitsData.self, from: file("units")) else { return nil }
        data.fromCache = true
        return data
    }

    // MARK: - 14 prochains jours

    public static func saveNextDays(_ data: NextDaysData) {
        save(data, to: file("next_days"))
    }

    public static func loadNextDays() -> NextDaysData? {
        guard var data = load(NextDaysData.self, from: file("next_days")) else { return nil }
        data.fromCache = true
        return data
    }

    // MARK: - Part de l'éolien GB

    public static func saveGbShare(_ data: GbShareData) {
        save(data, to: file("gb_share"))
    }

    public static func loadGbShare() -> GbShareData? {
        guard var data = load(GbShareData.self, from: file("gb_share")) else { return nil }
        data.fromCache = true
        return data
    }

    // MARK: - Fichiers

    private static func save<Value: Encodable>(_ value: Value, to url: URL?) {
        guard let url, let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func load<Value: Decodable>(_ type: Value.Type, from url: URL?) -> Value? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }
}
