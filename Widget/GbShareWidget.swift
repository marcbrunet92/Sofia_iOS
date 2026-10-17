import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Équivalent de widget/modern/SofiaGbShareGlanceWidget.kt :
/// part de Sofia dans l'éolien de Grande-Bretagne (PN de Sofia ÷ AGWS, dernière demi-heure publiée).
/// Petit = part de l'éolien en mer, moyen = + valeurs en MW/GW et part de tout l'éolien.

struct GbShareEntry: TimelineEntry {
    let date: Date
    let data: GbShareData
}

struct GbShareProvider: TimelineProvider {
    func placeholder(in context: Context) -> GbShareEntry {
        GbShareEntry(date: Date(), data: GbShareData(
            timeFrom: Date(),
            sofiaMw: 480,
            offshoreMw: 10_000,
            onshoreMw: 6_900,
            fetchedAt: Date(),
            fromCache: false
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (GbShareEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadGbShare()
            callback.call(GbShareEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GbShareEntry>) -> Void) {
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadGbShare()
            let entry = GbShareEntry(date: Date(), data: data)
            callback.call(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
        }
    }
}

struct SofiaGbShareWidget: Widget {
    let kind = "SofiaGbShareWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GbShareProvider()) { entry in
            GbShareWidgetView(entry: entry)
                .containerBackground(WidgetPalette.surface, for: .widget)
        }
        .configurationDisplayName(Text("widget_gb_label"))
        .description(Text("widget_gb_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct GbShareWidgetView: View {
    let entry: GbShareEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .systemSmall {
            GbShareCompactLayout(data: entry.data)
        } else {
            GbShareWideLayout(data: entry.data)
        }
    }
}

private enum GbShareFormat {
    static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f %%", locale: Locale.current, value)
    }

    static func gigawatts(_ mw: Double?) -> String {
        guard let mw else { return "—" }
        return String(format: "%.1f", locale: Locale.current, mw / 1_000)
    }

    /// Heure de la demi-heure AGWS : « HH:mm » aujourd'hui, « dd/MM HH:mm » sinon.
    static func agwsTime(_ data: GbShareData) -> String {
        guard let time = data.timeFrom else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = Calendar.current.isDateInToday(time) ? "HH:mm" : "dd/MM HH:mm"
        return formatter.string(from: time)
    }
}

private struct GbShareHeader: View {
    var body: some View {
        WText(L10n.string("widget_gb_header"), 10, WidgetPalette.muted, bold: true)
    }
}

private struct GbShareCompactLayout: View {
    let data: GbShareData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GbShareHeader()
            Spacer().frame(height: 4)
            WText(GbShareFormat.percent(data.offshoreSharePercent), 26, bold: true)
            WText(L10n.string("widget_gb_of_offshore"), 10, WidgetPalette.muted)
            Spacer(minLength: 4)
            WText(L10n.format("gb_source_format", GbShareFormat.agwsTime(data)), 9, WidgetPalette.muted)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct GbShareWideLayout: View {
    let data: GbShareData

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                GbShareHeader()
                Spacer().frame(height: 4)
                WText(GbShareFormat.percent(data.offshoreSharePercent), 30, bold: true)
                WText(L10n.string("widget_gb_of_offshore"), 10, WidgetPalette.muted)
                Spacer().frame(height: 4)
                WText(L10n.format("widget_gb_of_all_wind_format", GbShareFormat.percent(data.windSharePercent)), 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Dot(WidgetPalette.committed)
                    WText(L10n.format("widget_gb_sofia_format", data.sofiaMw.map { String(Int($0.rounded())) } ?? "—"), 11)
                }
                Spacer().frame(height: 4)
                WText(L10n.format("widget_gb_offshore_format", GbShareFormat.gigawatts(data.offshoreMw)), 11)
                WText(L10n.format("widget_gb_onshore_format", GbShareFormat.gigawatts(data.onshoreMw)), 11, WidgetPalette.muted)
                Spacer().frame(height: 6)
                WText(L10n.format("gb_source_format", GbShareFormat.agwsTime(data)), 9, WidgetPalette.muted)
                WText(updatedLabel(fromCache: data.fromCache, at: data.fetchedAt), 9, WidgetPalette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
