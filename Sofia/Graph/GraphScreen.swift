import Foundation
import SwiftUI
import SofiaCore

extension GraphDataset {
    /// Couleurs des séries (GraphScreen.kt).
    var color: Color {
        switch self {
        case .pn: return Color(red: 30 / 255, green: 136 / 255, blue: 229 / 255)
        case .b1610: return Color(red: 255 / 255, green: 152 / 255, blue: 0 / 255)
        case .weather: return Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255)
        }
    }
}

/// Équivalent de ui/graph/GraphScreen.kt.
struct GraphScreen: View {
    let state: GraphUiState
    let onRefresh: () async -> Void
    let onSelectWindow: (TimeWindow) -> Void
    let onToggleDataset: (GraphDataset) -> Void
    let onDismissError: () -> Void

    var body: some View {
        ZStack {
            SofiaColors.background
                .ignoresSafeArea()

            if state.isLoading && !state.hasData {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PullToRefreshContainer(isRefreshing: state.isRefreshing, onRefresh: onRefresh) {
                    content
                }
            }
        }
        .foregroundStyle(SofiaColors.onSurface)
    }

    private var content: some View {
        let series = Self.makeSeries(state)
        let latest = state.pnPoints.max { $0.timeFrom < $1.timeFrom }
        return VStack(spacing: 16) {
            TitleBanner(titleKey: "title_graph")
            if state.testMode {
                WarningBanner(text: L10n.string("test_mode_warning"))
            }
            if let errorKey = state.errorMessageKey {
                ErrorBanner(text: L10n.string(errorKey), onDismiss: onDismissError)
            }
            ProductionGaugeCard(
                currentMw: latest?.quantity ?? 0,
                maxCapacityMw: SofiaConstants.maxCapacityMw,
                dataTimestamp: latest?.timeFrom
            )
            DatasetSelector(selected: state.selectedDatasets, onSelect: onToggleDataset)
            GraphChartCard(
                left: series.left,
                right: series.right,
                selectedWindow: state.selectedWindow,
                onSelectWindow: onSelectWindow
            )
        }
        .padding(16)
    }

    /// Répartition des séries : MW à gauche, l'autre unité (vent) à droite ; si seule une unité
    /// non-MW est sélectionnée, elle passe à gauche.
    private static func makeSeries(_ state: GraphUiState) -> (left: [ChartSeries], right: [ChartSeries]) {
        let series: [ChartSeries] = state.selectedDatasets.map { dataset in
            switch dataset {
            case .pn:
                return ChartSeries(
                    id: dataset.labelKey,
                    points: state.pnPoints,
                    allowNegative: false,
                    unit: "MW",
                    color: dataset.color
                )
            case .b1610:
                // MWh par demi-heure → MW
                return ChartSeries(
                    id: dataset.labelKey,
                    points: state.b1610PointsMwh.map { $0.with(quantity: $0.quantity * 2) },
                    allowNegative: true,
                    unit: "MW",
                    color: dataset.color
                )
            case .weather:
                // Même conversion et même unité affichée que l'app Android
                return ChartSeries(
                    id: dataset.labelKey,
                    points: state.weatherPoints.map { $0.with(quantity: $0.quantity / 3.6) },
                    allowNegative: false,
                    unit: "km/h",
                    color: dataset.color
                )
            }
        }

        let mwSeries = series.filter { $0.unit == "MW" }
        let otherSeries = series.filter { $0.unit != "MW" }
        if !mwSeries.isEmpty && !otherSeries.isEmpty {
            return (mwSeries, otherSeries)
        } else if !otherSeries.isEmpty {
            return (otherSeries, [])
        } else {
            return (mwSeries, [])
        }
    }
}

private struct DatasetSelector: View {
    let selected: [GraphDataset]
    let onSelect: (GraphDataset) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([GraphDataset.weather, .pn, .b1610], id: \.self) { option in
                    SofiaFilterChip(
                        label: L10n.string(option.labelKey),
                        selected: selected.contains(option),
                        leadingColor: option.color
                    ) {
                        onSelect(option)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GraphChartCard: View {
    let left: [ChartSeries]
    let right: [ChartSeries]
    let selectedWindow: TimeWindow
    let onSelectWindow: (TimeWindow) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("chart_title")
                .font(SofiaType.titleMedium)
                .foregroundStyle(SofiaColors.onSurface)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeWindow.allCases, id: \.self) { window in
                        SofiaFilterChip(
                            label: L10n.string(window.labelKey),
                            selected: window == selectedWindow
                        ) {
                            onSelectWindow(window)
                        }
                    }
                }
            }
            ProductionChartMulti(left: left, right: right, tw: selectedWindow)
        }
        .padding(16)
        .sofiaCard()
    }
}
