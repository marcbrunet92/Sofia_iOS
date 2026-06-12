import Foundation
import SofiaCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// SofiaCoreSmokeTest
//
// Petit exécutable qui interroge l'API réelle (sofia.lemarc.fr) et affiche
// les snapshots obtenus (Production, B1610, Weather, REMIT).
// Utile pour vérifier rapidement que SofiaCore communique correctement
// avec le backend et que l'agrégation produit des résultats sensés.

let isoFmt: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

func printSeparator(_ title: String) {
    print("\n========== \(title) ==========")
}

func printTopWindows(_ top: TopWindows, label: String) {
    func fmt(_ p: TopPoint) -> String {
        let dateStr = p.maxDate.map { isoFmt.string(from: $0) } ?? "n/a"
        return "\(p.maxQuantity) @ \(dateStr)"
    }
    print("\(label) — all-time: \(fmt(top.allTime))")
    print("\(label) —      90d: \(fmt(top.last90Days))")
    print("\(label) —      30d: \(fmt(top.last30Days))")
    print("\(label) —       7d: \(fmt(top.last7Days))")
}

func printPointsSummary(_ points: [GraphPoint], label: String) {
    print("\(label): \(points.count) points")
    if let first = points.first {
        print("  first: \(isoFmt.string(from: first.timeFrom)) -> \(first.quantity)")
    }
    if let last = points.last {
        print("  last:  \(isoFmt.string(from: last.timeFrom)) -> \(last.quantity)")
    }
}

@main
struct SofiaCoreSmokeTest {
    static func main() async {
        let api = SofiaAPIService.shared
        let now = Date()
        let mode: AppMode = .normal // change to .test for T_HEYM11

        print("Sofia API smoke test — base URL: \(await api.baseURL)")
        print("Mode: \(mode.displayName), BMUs: \(mode.bmuIds)")
        print("History start: \(isoFmt.string(from: SofiaConstants.historyStart))")
        print("Now: \(isoFmt.string(from: now))")

        // MARK: - Production snapshot
        printSeparator("Production")
        do {
            let snapshot = try await api.fetchProductionSnapshot(mode: mode, now: now)
            printPointsSummary(snapshot.points, label: "Production points")
            print("Current MW: \(snapshot.currentMw)")
            print("Latest data timestamp: \(snapshot.latestDataTimestamp.map { isoFmt.string(from: $0) } ?? "n/a")")
            printTopWindows(snapshot.topProduction, label: "Top production")
        } catch {
            print("Error fetching production snapshot: \(error)")
        }

        // MARK: - B1610 snapshot
        printSeparator("B1610")
        do {
            let snapshot = try await api.fetchB1610Snapshot(mode: mode, now: now)
            printPointsSummary(snapshot.points, label: "B1610 points")
            print("Latest data timestamp: \(snapshot.latestDataTimestamp.map { isoFmt.string(from: $0) } ?? "n/a")")
            printTopWindows(snapshot.topB1610, label: "Top B1610")
        } catch {
            print("Error fetching B1610 snapshot: \(error)")
        }

        // MARK: - Weather snapshot
        printSeparator("Weather")
        do {
            let snapshot = try await api.fetchWeatherSnapshot(now: now)
            printPointsSummary(snapshot.points, label: "Weather points")
            print("Latest wind speed: \(snapshot.latestWindSpeed.map { "\($0)" } ?? "n/a")")
            print("Latest data timestamp: \(snapshot.latestDataTimestamp.map { isoFmt.string(from: $0) } ?? "n/a")")
        } catch {
            print("Error fetching weather snapshot: \(error)")
        }

        // MARK: - REMIT notices
        printSeparator("REMIT")
        do {
            let notices = try await api.fetchRemitNotices(mode: mode)
            print("Active REMIT notices: \(notices.count)")
            for notice in notices.prefix(5) {
                let start = notice.eventStartTime.map { isoFmt.string(from: $0) } ?? "n/a"
                let end = notice.eventEndTime.map { isoFmt.string(from: $0) } ?? "n/a"
                print("  #\(notice.id) [\(notice.bmuId)] \(notice.messageHeading) (\(start) -> \(end))")
            }
        } catch {
            print("Error fetching REMIT notices: \(error)")
        }

        print("\nDone.")
    }
}