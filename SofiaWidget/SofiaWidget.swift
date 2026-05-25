import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared data model (App Group)
// Both the app and widget read/write via UserDefaults(suiteName: "group.com.yourname.sofiamonitor")
// The main app writes the latest data; the widget reads it.

struct SofiaWidgetEntry: TimelineEntry {
    let date: Date
    let totalMW: Double
    let capacityMW: Double
    let lastAPIUpdate: Date?
    let isTestMode: Bool
    let isStale: Bool   // true if data is older than 10 min

    var capacityFactor: Double { min(totalMW / capacityMW, 1.0) }

    static var placeholder: SofiaWidgetEntry {
        SofiaWidgetEntry(date: Date(), totalMW: 420, capacityMW: 1400,
                         lastAPIUpdate: Date(), isTestMode: false, isStale: false)
    }

    static var empty: SofiaWidgetEntry {
        SofiaWidgetEntry(date: Date(), totalMW: 0, capacityMW: 1400,
                         lastAPIUpdate: nil, isTestMode: false, isStale: true)
    }
}

// MARK: - Shared defaults key (must match what the app writes)
enum SharedDefaults {
    static let suiteName = "group.com.yourname.sofiamonitor"  // ← change to your bundle ID
    static let totalMWKey = "widget_totalMW"
    static let lastUpdateKey = "widget_lastUpdate"
    static let isTestModeKey = "widget_isTestMode"
}

// MARK: - Timeline Provider
struct SofiaProvider: TimelineProvider {

    func placeholder(in context: Context) -> SofiaWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SofiaWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SofiaWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 5 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func loadEntry() -> SofiaWidgetEntry {
        let defaults = UserDefaults(suiteName: SharedDefaults.suiteName)
        let totalMW = defaults?.double(forKey: SharedDefaults.totalMWKey) ?? 0
        let lastUpdate = defaults?.object(forKey: SharedDefaults.lastUpdateKey) as? Date
        let isTestMode = defaults?.bool(forKey: SharedDefaults.isTestModeKey) ?? false

        let isStale: Bool
        if let lastUpdate {
            isStale = Date().timeIntervalSince(lastUpdate) > 600 // 10 min
        } else {
            isStale = true
        }

        return SofiaWidgetEntry(
            date: Date(),
            totalMW: totalMW,
            capacityMW: 1400,
            lastAPIUpdate: lastUpdate,
            isTestMode: isTestMode,
            isStale: isStale
        )
    }
}

// MARK: - Widget Views

struct SofiaWidgetEntryView: View {
    var entry: SofiaWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small widget: ring + MW
struct SmallWidgetView: View {
    let entry: SofiaWidgetEntry

    var ringColor: Color {
        entry.isStale ? .gray :
        entry.capacityFactor > 0.6 ? .green :
        entry.capacityFactor > 0.2 ? .blue : .cyan
    }

    var body: some View {
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(.black.gradient)

            VStack(spacing: 6) {
                // Ring gauge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 10)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: entry.capacityFactor)
                        .stroke(
                            AngularGradient(
                                colors: [ringColor.opacity(0.6), ringColor],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(entry.isStale ? "—" : String(format: "%.0f", entry.totalMW))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("MW")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Capacity factor
                if !entry.isStale {
                    Text(entry.capacityFactor, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ringColor)
                }

                // Test mode tag
                if entry.isTestMode {
                    Text("TEST")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.yellow, in: Capsule())
                        .foregroundStyle(.black)
                }
            }
            .padding(8)
        }
    }
}

// MARK: - Medium widget: ring + details
struct MediumWidgetView: View {
    let entry: SofiaWidgetEntry

    var ringColor: Color {
        entry.isStale ? .gray :
        entry.capacityFactor > 0.6 ? .green :
        entry.capacityFactor > 0.2 ? .blue : .cyan
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.black.gradient)

            HStack(spacing: 20) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 14)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: entry.capacityFactor)
                        .stroke(
                            AngularGradient(
                                colors: [ringColor.opacity(0.5), ringColor],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text(entry.isStale ? "—" : String(format: "%.1f", entry.totalMW))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("MW")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOFIA WIND FARM")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .kerning(0.5)
                        Text(entry.isStale ? "No data" :
                             "\(entry.capacityFactor, format: .percent.precision(.fractionLength(1))) of capacity")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(ringColor)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ringColor)
                                .frame(width: geo.size.width * entry.capacityFactor)
                        }
                    }
                    .frame(height: 6)

                    Text("/ \(Int(entry.capacityMW)) MW")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    // Timestamp
                    if let update = entry.lastAPIUpdate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                            Text(update.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    } else {
                        Text(entry.isStale ? "Stale data" : "Updating…")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if entry.isTestMode {
                        Text("⚠ TEST MODE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2), in: Capsule())
                            .foregroundStyle(.yellow)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }
}

// MARK: - Widget definition
struct SofiaWidget: Widget {
    let kind: String = "SofiaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SofiaProvider()) { entry in
            SofiaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sofia Wind Farm")
        .description("Real-time production over 1400 MW capacity.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    SofiaWidget()
} timeline: {
    SofiaWidgetEntry.placeholder
    SofiaWidgetEntry(date: Date(), totalMW: 0, capacityMW: 1400,
                     lastAPIUpdate: Date(), isTestMode: false, isStale: false)
}

#Preview(as: .systemMedium) {
    SofiaWidget()
} timeline: {
    SofiaWidgetEntry.placeholder
}
