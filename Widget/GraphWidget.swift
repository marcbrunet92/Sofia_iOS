import AppIntents
import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Équivalent de widget/modern/SofiaGraphGlanceWidget.kt + SofiaGraphConfig.kt :
/// courbe de production sur la fenêtre choisie à l'ajout du widget (24 h par défaut) ;
/// production engagée (PN, remplie) et, si la fenêtre est ≥ 7 jours, production réelle (B1610).

enum GraphWindowOption: String, AppEnum, CaseIterable {
    case hours6
    case hours24
    case hours48
    case days7
    case month1
    case month3
    case all

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "widget_config_time_window_title")

    static let caseDisplayRepresentations: [GraphWindowOption: DisplayRepresentation] = [
        .hours6: DisplayRepresentation(title: "time_window_long_6h"),
        .hours24: DisplayRepresentation(title: "time_window_long_24h"),
        .hours48: DisplayRepresentation(title: "time_window_long_48h"),
        .days7: DisplayRepresentation(title: "time_window_long_7d"),
        .month1: DisplayRepresentation(title: "time_window_long_1m"),
        .month3: DisplayRepresentation(title: "time_window_long_3m"),
        .all: DisplayRepresentation(title: "time_window_long_all"),
    ]

    var timeWindow: TimeWindow {
        switch self {
        case .hours6: return .hours6
        case .hours24: return .hours24
        case .hours48: return .hours48
        case .days7: return .days7
        case .month1: return .month1
        case .month3: return .month3
        case .all: return .all
        }
    }
}

/// Choix de la fenêtre de temps (« Modifier le widget »), comme SofiaGraphConfigActivity.
struct GraphWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "widget_config_time_window_title"
    static var description = IntentDescription("widget_config_time_window_subtitle")

    @Parameter(title: "widget_config_time_window_title", default: .hours24)
    var window: GraphWindowOption
}

struct GraphEntry: TimelineEntry {
    let date: Date
    let window: TimeWindow
    /// `nil` = chargement en cours (placeholder).
    let data: LiveData?
}

struct GraphProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GraphEntry {
        GraphEntry(date: Date(), window: .hours24, data: nil)
    }

    func snapshot(for configuration: GraphWidgetConfigurationIntent, in context: Context) async -> GraphEntry {
        let window = configuration.window.timeWindow
        if context.isPreview {
            return GraphEntry(
                date: Date(),
                window: window,
                data: .placeholder(window: window.duration ?? 30 * 86_400, includeActual: window.showsActual)
            )
        }
        return await Self.load(window)
    }

    func timeline(for configuration: GraphWidgetConfigurationIntent, in context: Context) async -> Timeline<GraphEntry> {
        let entry = await Self.load(configuration.window.timeWindow)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
    }

    private static func load(_ window: TimeWindow) async -> GraphEntry {
        let data = await SofiaWidgetData.loadLive(
            window: window.duration, // nil pour « All »
            includeActual: window.showsActual
        )
        return GraphEntry(date: Date(), window: window, data: data)
    }
}

struct SofiaGraphWidget: Widget {
    let kind = "SofiaGraphWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GraphWidgetConfigurationIntent.self, provider: GraphProvider()) { entry in
            GraphWidgetView(entry: entry)
                .containerBackground(WidgetPalette.surface, for: .widget)
        }
        .configurationDisplayName(Text("widget_graph_label"))
        .description(Text("widget_graph_description"))
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct GraphWidgetView: View {
    let entry: GraphEntry

    var body: some View {
        let window = entry.window
        let showActual = window.showsActual
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                WText(title, 10, WidgetPalette.muted, bold: true)
                Spacer(minLength: 6)
                Dot(WidgetPalette.committed)
                Spacer().frame(width: 4)
                WText(L10n.string("widget_graph_committed"), 10)
                if showActual {
                    Spacer().frame(width: 10)
                    Dot(WidgetPalette.actual)
                    Spacer().frame(width: 4)
                    WText(L10n.string("widget_graph_actual"), 10)
                }
            }
            Spacer().frame(height: 6)
            if let data = entry.data {
                if data.committed.isEmpty && (!showActual || data.actual.isEmpty) {
                    centeredMessage(L10n.string("widget_graph_no_data"))
                } else {
                    WidgetLineChart(lines: lines(data, showActual: showActual), from: data.from, to: data.to)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement()
                        .accessibilityLabel(Text(verbatim: L10n.format(
                            "widget_graph_content_description",
                            L10n.string(window.longLabelKey)
                        )))
                }
            } else {
                centeredMessage(L10n.string("widget_graph_loading"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var title: String {
        let shortTitle = L10n.string(entry.window.shortTitleKey)
        let base: String
        if entry.data?.fromCache == true {
            base = L10n.format("widget_graph_title_offline_format", shortTitle)
        } else {
            base = L10n.format("widget_graph_title_online_format", shortTitle)
        }
        let suffix = entry.data?.testMode == true ? L10n.string("widget_graph_title_test_suffix") : ""
        return base + suffix
    }

    private func lines(_ data: LiveData, showActual: Bool) -> [WidgetChartLine] {
        var result = [WidgetChartLine(points: data.committed, color: WidgetPalette.committed, filled: true)]
        if showActual {
            result.append(WidgetChartLine(points: data.actual, color: WidgetPalette.actual))
        }
        return result
    }

    private func centeredMessage(_ text: String) -> some View {
        WText(text, 12, WidgetPalette.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
