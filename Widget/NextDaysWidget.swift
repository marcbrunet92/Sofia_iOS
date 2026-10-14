import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Équivalent de widget/modern/SofiaNextDaysGlanceWidget.kt :
/// 14 prochains jours (UOU2T14D), une barre par jour. Petit = barres + aujourd'hui,
/// moyen = barres, aujourd'hui, premier et dernier jour.

struct NextDaysEntry: TimelineEntry {
    let date: Date
    let data: NextDaysData
}

struct NextDaysProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextDaysEntry {
        NextDaysEntry(date: Date(), data: Self.placeholderData())
    }

    func getSnapshot(in context: Context, completion: @escaping (NextDaysEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadNextDays()
            callback.call(NextDaysEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextDaysEntry>) -> Void) {
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadNextDays()
            let entry = NextDaysEntry(date: Date(), data: data)
            callback.call(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
        }
    }

    /// Aperçu de la galerie : 3 jours disponibles puis un arrêt.
    static func placeholderData() -> NextDaysData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<14).map { offset -> UouDay in
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return UouDay(date: UouDay.today(now: date), outputUsableMw: offset < 3 ? 400 : 0)
        }
        return NextDaysData(testMode: false, days: days, fetchedAt: Date(), fromCache: false)
    }
}

struct SofiaNextDaysWidget: Widget {
    let kind = "SofiaNextDaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextDaysProvider()) { entry in
            NextDaysWidgetView(entry: entry)
                .containerBackground(WidgetPalette.surface, for: .widget)
        }
        .configurationDisplayName(Text("widget_next_days_label"))
        .description(Text("widget_next_days_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct NextDaysWidgetView: View {
    let entry: NextDaysEntry

    @Environment(\.widgetFamily) var family

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    var body: some View {
        let wide = family != .systemSmall
        let data = entry.data
        let today = UouDay.today()
        let days = Array(data.days.filter { $0.date >= today }.prefix(14))
        // Échelle : 1 400 MW pour Sofia ; en mode test, la plus grande valeur
        let scale = data.testMode ? (days.map(\.outputUsableMw).max() ?? 1) : SofiaConstants.maxCapacityMw

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                WText(L10n.string(wide ? "widget_next_days_header" : "widget_next_days_header_short"), 10, WidgetPalette.muted, bold: true)
                if data.testMode {
                    Spacer(minLength: 4)
                    WText(L10n.string("widget_live_test"), 9, WidgetPalette.bad, bold: true)
                }
            }
            if let first = days.first {
                WText(L10n.format("widget_next_days_today_format", Int(first.outputUsableMw.rounded())), wide ? 16 : 13, bold: true)
            }
            Spacer().frame(height: 6)
            if days.isEmpty {
                WText(L10n.string("widget_graph_no_data"), 12, WidgetPalette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DayBars(values: days.map(\.outputUsableMw), scale: scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if days.count > 1, let first = days.first, let last = days.last {
                Spacer().frame(height: 4)
                HStack {
                    WText(Self.label(first, wide: wide), 9, WidgetPalette.muted)
                    Spacer(minLength: 4)
                    WText(Self.label(last, wide: wide), 9, WidgetPalette.muted)
                }
            }
            if wide {
                WText(updatedLabel(fromCache: data.fromCache, at: data.fetchedAt), 9, WidgetPalette.muted)
            }
        }
        .padding(wide ? 12 : 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// « 15 oct. · 401 MW » en moyen, « 15 oct. » en petit.
    private static func label(_ day: UouDay, wide: Bool) -> String {
        let date = day.localDate.map { dayFormatter.string(from: $0) } ?? day.date
        return wide ? L10n.format("next_days_label_format", date, Int(day.outputUsableMw.rounded())) : date
    }
}

/// Une barre par jour, hauteur ∝ valeur / échelle ; un jour à 0 MW = trait rouge au pied.
/// Mêmes couleurs que la carte « 14 prochains jours » de l'app.
private struct DayBars: View {
    let values: [Double]
    let scale: Double

    private static let available = Color(widgetHex: 0x1D9E75)
    private static let unavailable = Color(widgetHex: 0xD85A30)

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(values.indices, id: \.self) { index in
                    let fraction = min(max(values[index] / max(scale, 1), 0), 1)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(fraction > 0 ? Self.available : Self.unavailable)
                        .frame(height: fraction > 0 ? proxy.size.height * max(fraction, 0.07) : 2)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
    }
}
