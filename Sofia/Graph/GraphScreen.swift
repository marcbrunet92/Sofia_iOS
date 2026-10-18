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
        case .mel: return Color(red: 29 / 255, green: 158 / 255, blue: 117 / 255)
        }
    }

    /// Ordre de dessin : le MEL (zone colorée) passe sous les courbes de production.
    static let drawOrder: [GraphDataset] = [.mel, .pn, .b1610, .weather]
}

/// Équivalent de ui/graph/GraphScreen.kt.
struct GraphScreen: View {
    let state: GraphUiState
    /// Hauteur réservée sous le contenu (barre d'onglets flottante).
    var bottomInset: CGFloat = 0
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
                // Écran à hauteur fixe : le graphique prend toute la place restante, rien ne défile.
                // Le ScrollView est gardé pour le tirer-pour-rafraîchir ; il ne défile réellement que
                // sur les très petits écrans, où la hauteur minimale dépasse l'écran.
                GeometryReader { proxy in
                    PullToRefreshContainer(isRefreshing: state.isRefreshing, onRefresh: onRefresh) {
                        content
                            .frame(height: max(proxy.size.height, Self.minScreenHeight + bottomInset))
                    }
                }
            }
        }
        .foregroundStyle(SofiaColors.onSurface)
    }

    /// En dessous (hors barre d'onglets), le graphique deviendrait illisible : l'écran défile alors.
    private static let minScreenHeight: CGFloat = 620

    private var content: some View {
        let series = Self.makeSeries(state)
        let latest = state.pnPoints.max { $0.timeFrom < $1.timeFrom }
        return VStack(spacing: 16) {
            TitleBanner(titleKey: "title_graph")
            if let errorKey = state.errorMessageKey {
                ErrorBanner(text: L10n.string(errorKey), onDismiss: onDismissError)
            }
            ProductionGaugeCompactCard(
                currentMw: latest?.quantity ?? 0,
                maxCapacityMw: SofiaConstants.maxCapacityMw,
                dataTimestamp: latest?.timeFrom,
                gbSharePercent: gbSharePercent(state.gbContext, pnPoints: state.pnPoints)
            )
            GraphChartCard(
                left: series.left,
                right: series.right,
                selectedWindow: state.selectedWindow,
                onSelectWindow: onSelectWindow,
                selectedDatasets: state.selectedDatasets,
                onSelectDataset: onToggleDataset
            )
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .padding(.bottom, bottomInset)
    }

    /// Répartition des séries : MW à gauche, l'autre unité (vent) à droite ; si seule une unité
    /// non-MW est sélectionnée, elle passe à gauche.
    private static func makeSeries(_ state: GraphUiState) -> (left: [ChartSeries], right: [ChartSeries]) {
        let ordered = state.selectedDatasets.sorted {
            (GraphDataset.drawOrder.firstIndex(of: $0) ?? 0) < (GraphDataset.drawOrder.firstIndex(of: $1) ?? 0)
        }
        let series: [ChartSeries] = ordered.map { dataset in
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
                return ChartSeries(
                    id: dataset.labelKey,
                    points: state.weatherPoints,
                    allowNegative: false,
                    unit: "km/h",
                    color: dataset.color
                )
            case .mel:
                return ChartSeries(
                    id: dataset.labelKey,
                    points: state.melPoints,
                    allowNegative: false,
                    unit: "MW",
                    color: dataset.color,
                    filled: true
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
        FillRowLayout(spacing: 8) {
            ForEach([GraphDataset.b1610, .pn, .weather], id: \.self) { option in
                SofiaFilterChip(
                    label: L10n.string(option.labelKey),
                    selected: selected.contains(option),
                    leadingColor: option.color,
                    fillsWidth: true
                ) {
                    onSelect(option)
                }
            }
        }
    }
}

/// Chaque chip garde sa largeur naturelle et l'espace restant est réparti à parts égales, pour que
/// l'ensemble occupe toute la largeur ; s'il manque de la place, les largeurs sont réduites
/// proportionnellement.
private struct FillRowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let naturalWidth = sizes.reduce(0) { $0 + $1.width } + totalSpacing(subviews.count)
        return CGSize(width: proposal.width ?? naturalWidth, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let natural = subviews.map { $0.sizeThatFits(.unspecified).width }
        let available = bounds.width - totalSpacing(subviews.count)
        let naturalSum = natural.reduce(0, +)
        let widths: [CGFloat]
        if naturalSum <= 0 {
            widths = natural
        } else if naturalSum <= available {
            let extra = (available - naturalSum) / CGFloat(natural.count)
            widths = natural.map { $0 + extra }
        } else {
            widths = natural.map { $0 * available / naturalSum }
        }
        var x = bounds.minX
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: widths[index], height: bounds.height)
            )
            x += widths[index] + spacing
        }
    }

    private func totalSpacing(_ count: Int) -> CGFloat {
        spacing * CGFloat(max(count - 1, 0))
    }
}

private struct GraphChartCard: View {
    let left: [ChartSeries]
    let right: [ChartSeries]
    let selectedWindow: TimeWindow
    let onSelectWindow: (TimeWindow) -> Void
    let selectedDatasets: [GraphDataset]
    let onSelectDataset: (GraphDataset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DatasetSelector(selected: selectedDatasets, onSelect: onSelectDataset)
            // Centrés s'ils tiennent sur la largeur, défilants sinon
            ViewThatFits(in: .horizontal) {
                windowChips
                ScrollView(.horizontal, showsIndicators: false) {
                    windowChips
                }
            }
            .frame(maxWidth: .infinity)
            ProductionChartMulti(left: left, right: right, tw: selectedWindow, height: nil)
            if selectedDatasets.contains(.b1610) {
                Text("chart_subtitle")
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .sofiaCard()
    }

    private var windowChips: some View {
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
}
