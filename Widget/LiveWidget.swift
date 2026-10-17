import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Équivalent de widget/modern/SofiaLiveGlanceWidget.kt :
/// production en direct, petit = jauge seule, moyen = jauge + détails.

struct LiveEntry: TimelineEntry {
    let date: Date
    let data: LiveData
}

/// Rend un callback WidgetKit utilisable depuis une tâche asynchrone.
struct WidgetCompletion<Value>: @unchecked Sendable {
    let call: (Value) -> Void
}

struct LiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> LiveEntry {
        LiveEntry(date: Date(), data: .placeholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadLive()
            callback.call(LiveEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveEntry>) -> Void) {
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadLive()
            let entry = LiveEntry(date: Date(), data: data)
            // Rafraîchissement toutes les ~30 min, comme updatePeriodMillis / WorkManager
            callback.call(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
        }
    }
}

struct SofiaLiveWidget: Widget {
    let kind = "SofiaLiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiveProvider()) { entry in
            LiveWidgetView(entry: entry)
                .containerBackground(WidgetPalette.surface, for: .widget)
        }
        .configurationDisplayName(Text("widget_live_label"))
        .description(Text("widget_live_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct LiveWidgetView: View {
    let entry: LiveEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .systemSmall {
            LiveCompactLayout(data: entry.data)
        } else {
            LiveWideLayout(data: entry.data)
        }
    }
}

private func livePercent(_ data: LiveData) -> Int {
    let percent = Int((data.currentMw / SofiaConstants.maxCapacityMw * 100).rounded())
    return min(max(percent, 0), 100)
}

private func liveFraction(_ data: LiveData) -> Double {
    data.currentMw / SofiaConstants.maxCapacityMw
}

private struct LiveCompactLayout: View {
    let data: LiveData

    var body: some View {
        ZStack {
            WidgetGauge(fraction: liveFraction(data))
            VStack(spacing: 0) {
                WText(String(Int(data.currentMw.rounded())), 22, bold: true)
                WText(L10n.string("widget_live_mw"), 11, WidgetPalette.muted)
            }
            .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LiveWideLayout: View {
    let data: LiveData

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                WidgetGauge(fraction: liveFraction(data))
                WText("\(livePercent(data))%", 18, bold: true)
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 0) {
                WText(L10n.string("widget_live_sofia_offshore"), 10, WidgetPalette.muted, bold: true)
                WText(L10n.format("widget_mw_value", Int(data.currentMw.rounded())), 28, bold: true)
                WText(
                    L10n.format("widget_live_installed_capacity_format", Int(SofiaConstants.maxCapacityMw.rounded())),
                    11,
                    WidgetPalette.muted
                )
                Spacer().frame(height: 6)
                HStack(spacing: 6) {
                    Dot(WidgetPalette.actual)
                    WText(actualText, 11)
                }
                Spacer().frame(height: 2)
                WText(updatedLabel(fromCache: data.fromCache, at: data.to), 10, WidgetPalette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actualText: String {
        guard let actualMw = data.actualMw else { return L10n.string("widget_live_actual_empty") }
        return L10n.format("widget_live_actual_format", Int(actualMw.rounded()))
    }
}
