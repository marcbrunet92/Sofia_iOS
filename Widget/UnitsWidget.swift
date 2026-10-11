import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Équivalent de widget/modern/SofiaUnitsGlanceWidget.kt :
/// disponibilité (REMIT) par unité, petit = grille de 4 tuiles, moyen = 4 tuiles + total.

struct UnitsEntry: TimelineEntry {
    let date: Date
    let data: UnitsData
}

struct UnitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> UnitsEntry {
        UnitsEntry(date: Date(), data: Self.placeholderData())
    }

    func getSnapshot(in context: Context, completion: @escaping (UnitsEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadUnits()
            callback.call(UnitsEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UnitsEntry>) -> Void) {
        let callback = WidgetCompletion(call: completion)
        Task {
            let data = await SofiaWidgetData.loadUnits()
            let entry = UnitsEntry(date: Date(), data: data)
            callback.call(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
        }
    }

    static func placeholderData() -> UnitsData {
        let now = Date()
        return UnitsData(
            testMode: false,
            units: computeUnitStatuses([], testMode: false, now: now),
            fetchedAt: now,
            fromCache: false
        )
    }
}

struct SofiaUnitsWidget: Widget {
    let kind = "SofiaUnitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnitsProvider()) { entry in
            UnitsWidgetView(entry: entry)
                .containerBackground(WidgetPalette.surface, for: .widget)
        }
        .configurationDisplayName(Text("widget_units_label"))
        .description(Text("widget_units_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct UnitsWidgetView: View {
    let entry: UnitsEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .systemSmall {
            UnitsCompactLayout(data: entry.data)
        } else {
            UnitsWideLayout(data: entry.data)
        }
    }
}

private struct UnitsWideLayout: View {
    let data: UnitsData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                WText(L10n.string("widget_units_header"), 10, WidgetPalette.muted, bold: true)
                Spacer(minLength: 4)
                WText(totalText, 11, bold: true)
            }
            Spacer().frame(height: 8)
            HStack(spacing: 6) {
                ForEach(data.units, id: \.bmuId) { unit in
                    UnitTile(unit: unit, compact: false)
                }
            }
            .frame(maxHeight: .infinity)
            Spacer().frame(height: 6)
            WText(updatedLabel(fromCache: data.fromCache, at: data.fetchedAt), 9, WidgetPalette.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var totalText: String {
        let available = Int(data.totalAvailable.rounded())
        if data.totalNormal > 0 {
            return "\(available) / \(Int(data.totalNormal.rounded())) MW"
        }
        return "\(available) MW"
    }
}

private struct UnitsCompactLayout: View {
    let data: UnitsData

    var body: some View {
        let rows = stride(from: 0, to: data.units.count, by: 2).map { start in
            Array(data.units[start..<min(start + 2, data.units.count)])
        }
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.bmuId) { unit in
                        UnitTile(unit: unit, compact: true)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct UnitTile: View {
    let unit: UnitStatus
    let compact: Bool

    var body: some View {
        let color = unit.level.widgetColor
        let mw = unit.availableMw.map { String(Int($0.rounded())) } ?? "—"
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Dot(color, size: 6)
                WText(compact ? unit.shortLabel : unit.label, compact ? 10 : 9, WidgetPalette.muted, bold: true)
            }
            if compact {
                WText("\(mw) \(L10n.string("unit_mw"))", 13, color, bold: true)
            } else {
                WText(mw, 18, color, bold: true)
                WText(L10n.string("unit_mw"), 9, WidgetPalette.muted)
                Spacer().frame(height: 4)
                WidgetProgressBar(fraction: unit.fraction, color: color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, compact ? 4 : 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetPalette.tile, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
