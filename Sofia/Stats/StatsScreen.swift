import Charts
import Foundation
import SwiftUI
import SofiaCore

/// Onglet Statistiques : bilan d'une période (énergie, facteur de charge, pic…), énergie par
/// jour, disponibilité prévue, records, production selon le vent, production par unité et
/// contexte national.
struct StatsScreen: View {
    /// Séries du graphique (PN, B1610, vent), déjà en mémoire.
    let graph: GraphUiState
    let state: StatsUiState
    var windUnit: WindSpeedUnit = .metersPerSecond
    /// Hauteur réservée sous le contenu (barre d'onglets flottante).
    var bottomInset: CGFloat = 0
    let onRefresh: () async -> Void
    let onSelectPeriod: (StatsPeriod) -> Void

    var body: some View {
        ZStack {
            SofiaColors.background
                .ignoresSafeArea()

            if graph.isLoading && !graph.hasData {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PullToRefreshContainer(isRefreshing: graph.isRefreshing, onRefresh: onRefresh) {
                    content
                }
            }
        }
        .foregroundStyle(SofiaColors.onSurface)
    }

    private var content: some View {
        let now = Date()
        let stats = periodStats(graph.pnPoints, period: state.period, capacityMw: SofiaConstants.maxCapacityMw, now: now)
        return VStack(spacing: 16) {
            TitleBanner(titleKey: "title_stats")
            PeriodSelector(selected: state.period, onSelect: onSelectPeriod)
            SummaryCard(stats: stats)
            DailyEnergyCard(
                days: dailyEnergy(pnMw: graph.pnPoints, b1610Mwh: graph.b1610PointsMwh, days: 30, now: now)
            )
            NextDaysCard(days: graph.uouDays, capacityMw: SofiaConstants.maxCapacityMw)
            RecordsCard(top: calculateTopWindows(graph.pnPoints, now: now))
            PowerCurveCard(
                bins: powerCurve(
                    pnMw: graph.pnPoints,
                    windKmh: graph.weatherPoints,
                    from: state.period.start(now: now),
                    now: now
                ),
                windUnit: windUnit
            )
            if !state.unitOutputs.isEmpty {
                UnitOutputsCard(outputs: state.unitOutputs)
            }
            GbContextDetailCard(context: graph.gbContext, pnPoints: graph.pnPoints)
            Text("stats_footnote")
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
        .padding(16)
        .padding(.bottom, bottomInset)
    }
}

/// Formats des nombres de l'onglet, dans la langue de l'appareil.
enum StatsFormat {
    /// « 850 MWh » sous 1 GWh, « 12,3 GWh » au-delà.
    static func energy(_ mwh: Double) -> String {
        if abs(mwh) >= 1_000 {
            return L10n.format("stats_gwh_format", decimal(mwh / 1_000, digits: 1))
        }
        return L10n.format("stats_mwh_format", decimal(mwh, digits: 0))
    }

    static func megawatts(_ mw: Double) -> String {
        L10n.format("mw_value_format", Int(mw.rounded()))
    }

    /// « 42 % »
    static func percent(_ fraction: Double) -> String {
        L10n.format("stats_percent_format", Int((fraction * 100).rounded()))
    }

    /// Nombre avec séparateur de milliers et `digits` décimales.
    static func decimal(_ value: Double, digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("d MMM HH:mm")
        return formatter
    }()

    /// « 22 oct. 18:00 », dans le fuseau de l'appareil.
    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

private struct PeriodSelector: View {
    let selected: StatsPeriod
    let onSelect: (StatsPeriod) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                SofiaFilterChip(
                    label: L10n.string(period.labelKey),
                    selected: period == selected
                ) {
                    onSelect(period)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Bilan de la période : six tuiles.
private struct SummaryCard: View {
    let stats: PeriodStats?

    private static let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "stats_summary_title", subtitleKey: "stats_summary_subtitle")
            if let stats {
                LazyVGrid(columns: Self.columns, spacing: 8) {
                    StatTile(
                        label: L10n.string("stats_energy_label"),
                        value: StatsFormat.energy(stats.energyMwh),
                        caption: L10n.format("stats_hours_format", StatsFormat.decimal(stats.hours, digits: 0))
                    )
                    StatTile(
                        label: L10n.string("stats_capacity_factor_label"),
                        value: StatsFormat.percent(stats.capacityFactor),
                        caption: L10n.format("stats_of_capacity_format", Int(SofiaConstants.maxCapacityMw.rounded()))
                    )
                    StatTile(
                        label: L10n.string("stats_average_label"),
                        value: StatsFormat.megawatts(stats.averageMw),
                        caption: L10n.string("stats_average_caption")
                    )
                    StatTile(
                        label: L10n.string("stats_peak_label"),
                        value: StatsFormat.megawatts(stats.peakMw),
                        caption: stats.peakDate.map { StatsFormat.date($0) } ?? "—"
                    )
                    StatTile(
                        label: L10n.string("stats_generating_label"),
                        value: StatsFormat.percent(stats.generatingShare),
                        caption: L10n.string("stats_generating_caption")
                    )
                    StatTile(
                        label: L10n.string("stats_homes_label"),
                        value: StatsFormat.decimal(stats.equivalentHomes, digits: 0),
                        caption: L10n.string("stats_homes_caption")
                    )
                }
            } else {
                Text("stats_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }
}

/// Énergie par jour sur 30 jours : compteur (B1610) quand il est arrivé, sinon estimation PN.
private struct DailyEnergyCard: View {
    let days: [DailyEnergy]

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "stats_daily_title", subtitleKey: "stats_daily_subtitle")
            if days.contains(where: { $0.energyMwh != 0 }) {
                Chart(days) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("GWh", day.energyMwh / 1_000)
                    )
                    .foregroundStyle(day.metered ? GraphDataset.b1610.color : GraphDataset.pn.color)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
                HStack(spacing: 16) {
                    LegendItem(color: GraphDataset.b1610.color, titleKey: "stats_daily_metered")
                    LegendItem(color: GraphDataset.pn.color, titleKey: "stats_daily_estimated")
                }
            } else {
                Text("stats_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let titleKey: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(LocalizedStringKey(titleKey))
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
        }
    }
}

/// Records de production annoncée : 7, 30, 90 jours et tout l'historique.
private struct RecordsCard: View {
    let top: TopWindows

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "stats_records_title", subtitleKey: "stats_records_subtitle")
            RecordRow(labelKey: "time_window_long_7d", point: top.last7Days)
            RecordRow(labelKey: "time_window_long_1m", point: top.last30Days)
            RecordRow(labelKey: "time_window_long_3m", point: top.last90Days)
            RecordRow(labelKey: "time_window_long_all", point: top.allTime)
        }
    }
}

private struct RecordRow: View {
    let labelKey: String
    let point: TopPoint

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(LocalizedStringKey(labelKey))
                .font(SofiaType.bodyMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let date = point.maxDate {
                Text(verbatim: StatsFormat.date(date))
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
                Text(verbatim: StatsFormat.megawatts(point.maxQuantity))
                    .font(SofiaType.bodyMedium)
                    .fontWeight(.semibold)
            } else {
                Text(verbatim: "—")
                    .font(SofiaType.bodyMedium)
            }
        }
    }
}

/// Courbe de puissance observée : production annoncée moyenne selon la vitesse du vent.
private struct PowerCurveCard: View {
    let bins: [PowerCurveBin]
    let windUnit: WindSpeedUnit

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "stats_curve_title", subtitleKey: "stats_curve_subtitle")
            if bins.count >= 2 {
                Chart(bins) { bin in
                    AreaMark(
                        x: .value("Wind", windUnit.fromKmh(bin.centerMs * 3.6)),
                        y: .value("MW", bin.averageMw)
                    )
                    .foregroundStyle(GraphDataset.weather.color.opacity(0.18))
                    .interpolationMethod(.monotone)
                    LineMark(
                        x: .value("Wind", windUnit.fromKmh(bin.centerMs * 3.6)),
                        y: .value("MW", bin.averageMw)
                    )
                    .foregroundStyle(GraphDataset.weather.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                    PointMark(
                        x: .value("Wind", windUnit.fromKmh(bin.centerMs * 3.6)),
                        y: .value("MW", bin.averageMw)
                    )
                    .foregroundStyle(GraphDataset.weather.color)
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
                Text(verbatim: L10n.format("stats_curve_axis_format", windUnit.symbol))
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            } else {
                Text("stats_curve_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }
}

/// Dernière production annoncée de chaque unité, rapportée à sa capacité installée.
private struct UnitOutputsCard: View {
    let outputs: [UnitOutput]

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "stats_units_title", subtitleKey: "stats_units_subtitle")
            ForEach(outputs) { unit in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: L10n.format("remit_unit_format", unit.shortLabel))
                            .font(SofiaType.bodyMedium)
                            .fontWeight(.medium)
                        Spacer()
                        Text(verbatim: Self.valueText(unit))
                            .font(SofiaType.bodyMedium)
                    }
                    LinearProgressBar(fraction: unit.fraction, color: SofiaColors.primary)
                }
            }
        }
    }

    /// « 168 / 336 MW », « 168 MW » sans capacité connue, « — » sans donnée.
    private static func valueText(_ unit: UnitOutput) -> String {
        guard let output = unit.outputMw else { return "—" }
        guard let capacity = unit.capacityMw else { return StatsFormat.megawatts(output) }
        return L10n.format("stats_unit_output_format", Int(output.rounded()), Int(capacity.rounded()))
    }
}
