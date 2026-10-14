import Foundation
import Charts
import SwiftUI
import SofiaCore

/// Série affichée par le graphique (ChartSeries de ProductionChartContent.kt).
struct ChartSeries: Identifiable {
    let id: String
    let points: [GraphPoint]
    let allowNegative: Bool
    let unit: String
    let color: Color
    /// Zone sous la courbe colorée (MEL : plafond de production).
    var filled: Bool = false
}

/// ProductionChartMulti.kt : écarte les séries vides et affiche le placeholder s'il ne reste rien.
struct ProductionChartMulti: View {
    let left: [ChartSeries]
    var right: [ChartSeries] = []
    let tw: TimeWindow

    var body: some View {
        let leftFiltered = left.filter { !$0.points.isEmpty }
        let rightFiltered = right.filter { !$0.points.isEmpty }
        if leftFiltered.isEmpty && rightFiltered.isEmpty {
            EmptyChartPlaceholder()
        } else if leftFiltered.isEmpty {
            ProductionChartContent(left: rightFiltered, right: [], tw: tw)
        } else {
            ProductionChartContent(left: leftFiltered, right: rightFiltered, tw: tw)
        }
    }
}

/// ProductionChartContent.kt : toutes les données sont tracées ; la fenêtre de temps ne change
/// que le zoom (durée visible) et la position de défilement, toujours calée sur la fin des données.
/// Défilement horizontal et pincement pour zoomer ; axe de gauche en MW, axe de droite pour
/// l'autre unité (vent).
struct ProductionChartContent: View {
    let left: [ChartSeries]
    let right: [ChartSeries]
    let tw: TimeWindow

    /// Bord gauche de la zone visible.
    @State private var scrollPosition: Date
    /// Durée visible (zoom).
    @State private var visibleLength: TimeInterval
    @State private var pinchStartLength: TimeInterval? = nil
    @State private var cache = ChartPlotCache()

    private static let minimumVisibleLength: TimeInterval = 2 * 3_600

    init(left: [ChartSeries], right: [ChartSeries], tw: TimeWindow) {
        self.left = left
        self.right = right
        self.tw = tw
        let bounds = ChartBounds(series: left + right)
        let length = bounds.windowLength(for: tw)
        _visibleLength = State(initialValue: length)
        _scrollPosition = State(initialValue: bounds.latestScroll(length: length))
    }

    var body: some View {
        let bounds = ChartBounds(series: left + right)
        let length = Swift.min(visibleLength, bounds.span)
        let plot = cache.plot(left: left, right: right, bounds: bounds, length: length, scrollPosition: scrollPosition)
        // Format choisi d'après la durée RÉELLEMENT visible : il suit aussi les pincements.
        let format = AxisTimeFormat.forVisibleRange(span: length, start: scrollPosition, dataEnd: bounds.end)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verbatim: left.first?.unit ?? "")
                Spacer()
                Text(verbatim: right.first?.unit ?? "")
            }
            .font(.system(size: 11))
            .foregroundStyle(SofiaColors.onSurface)

            chart(plot: plot, bounds: bounds, length: length, format: format)
                .frame(height: 280)
                .simultaneousGesture(magnifyGesture(bounds: bounds, length: length))
        }
        .onChange(of: tw) { _, newWindow in
            applyWindow(newWindow)
        }
        .onChange(of: bounds) { oldBounds, newBounds in
            followData(from: oldBounds, to: newBounds)
        }
    }

    private func chart(plot: ChartPlot, bounds: ChartBounds, length: TimeInterval, format: AxisTimeFormat) -> some View {
        Chart {
            // Zones colorées d'abord : elles passent sous les courbes
            ForEach(plot.series.filter(\.filled)) { series in
                ForEach(series.points, id: \.timeFrom) { point in
                    AreaMark(
                        x: .value("Time", point.timeFrom),
                        yStart: .value("Base", 0.0),
                        yEnd: .value("Value", point.quantity * series.scale)
                    )
                    .foregroundStyle(series.color.opacity(0.2))
                    .interpolationMethod(.monotone)
                }
            }
            ForEach(plot.series) { series in
                ForEach(series.points, id: \.timeFrom) { point in
                    LineMark(
                        x: .value("Time", point.timeFrom),
                        y: .value("Value", point.quantity * series.scale),
                        series: .value("Series", series.id)
                    )
                    .foregroundStyle(series.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
            }
        }
        .chartLegend(.hidden)
        .chartXScale(domain: bounds.start...bounds.domainEnd)
        .chartYScale(domain: plot.yScale.lower...plot.yScale.upper)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: length)
        .chartScrollPosition(x: $scrollPosition)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Text(verbatim: Self.timeLabel(value, format: format))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: plot.yScale.ticks) { value in
                AxisGridLine()
                AxisValueLabel {
                    Text(verbatim: Self.valueLabel(value, factor: 1))
                }
            }
            AxisMarks(position: .trailing, values: plot.rightTicks) { value in
                AxisValueLabel {
                    Text(verbatim: Self.valueLabel(value, factor: plot.rightFactor))
                }
            }
        }
    }

    private func magnifyGesture(bounds: ChartBounds, length: TimeInterval) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let startLength = pinchStartLength ?? length
                if pinchStartLength == nil {
                    pinchStartLength = startLength
                }
                let magnification = Swift.max(Double(value.magnification), 0.01)
                let newLength = Swift.min(
                    Swift.max(startLength / magnification, Self.minimumVisibleLength),
                    bounds.span
                )
                // Zoom centré sur le milieu de la zone visible
                let center = scrollPosition.addingTimeInterval(length / 2)
                visibleLength = newLength
                scrollPosition = bounds.clampedScroll(center.addingTimeInterval(-newLength / 2), length: newLength)
            }
            .onEnded { _ in
                pinchStartLength = nil
            }
    }

    /// Changement de chip : zoom sur la fenêtre et retour à la fin des données.
    private func applyWindow(_ window: TimeWindow) {
        let bounds = ChartBounds(series: left + right)
        let length = bounds.windowLength(for: window)
        withAnimation(.easeInOut(duration: 0.35)) {
            visibleLength = length
            scrollPosition = bounds.latestScroll(length: length)
        }
    }

    /// Nouvelles données : on reste calé sur la fin si on y était.
    private func followData(from oldBounds: ChartBounds, to newBounds: ChartBounds) {
        let length = Swift.min(visibleLength, newBounds.span)
        let visibleEnd = scrollPosition.addingTimeInterval(length)
        let wasAtEnd = visibleEnd >= oldBounds.domainEnd.addingTimeInterval(-length * 0.05)
        let target = wasAtEnd ? newBounds.latestScroll(length: length) : scrollPosition
        scrollPosition = newBounds.clampedScroll(target, length: length)
    }

    nonisolated private static func timeLabel(_ value: AxisValue, format: AxisTimeFormat) -> String {
        guard let date = value.as(Date.self) else { return "" }
        return format.string(from: date)
    }

    nonisolated private static func valueLabel(_ value: AxisValue, factor: Double) -> String {
        guard let number = value.as(Double.self), factor != 0 else { return "" }
        return String(Int((number / factor).rounded()))
    }
}

// MARK: - Axe temporel

/// Format de l'axe X choisi d'après la durée visible.
enum AxisTimeFormat: CaseIterable {
    /// ≤ 12 h
    case hours
    /// ≤ 3 j ET dans les 3 derniers jours de données
    case dayHours
    /// ≤ 1 an
    case dates
    /// > 1 an
    case months

    nonisolated var pattern: String {
        switch self {
        case .hours: return "HH:mm"
        case .dayHours: return "EEE HH:mm"
        case .dates: return "dd/MM"
        case .months: return "MM/yy"
        }
    }

    static func forVisibleRange(span: TimeInterval, start: Date, dataEnd: Date) -> AxisTimeFormat {
        let recent: TimeInterval = 3 * 86_400
        // Petite tolérance : la fenêtre visible est approximative
        let tolerance = span * 0.05
        let isRecent = start >= dataEnd.addingTimeInterval(-recent - tolerance)
        if span <= 12 * 3_600 { return .hours }
        if span <= recent && isRecent { return .dayHours }
        if span <= 365 * 86_400 { return .dates }
        return .months
    }

    nonisolated func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

// MARK: - Données tracées

/// Étendue temporelle des séries (x = timeFrom de chaque point).
struct ChartBounds: Equatable {
    let start: Date
    let end: Date

    init(series: [ChartSeries]) {
        let starts = series.compactMap { $0.points.first?.timeFrom }
        let ends = series.compactMap { $0.points.last?.timeFrom }
        let start = starts.min() ?? Date()
        self.start = start
        self.end = Swift.max(ends.max() ?? start, start)
    }

    /// Durée totale (au moins une demi-heure pour garder un domaine valide).
    var span: TimeInterval {
        Swift.max(end.timeIntervalSince(start), 1_800)
    }

    var domainEnd: Date {
        start.addingTimeInterval(span)
    }

    /// Durée visible pour une fenêtre (« All » ou fenêtre plus longue que les données : tout voir).
    func windowLength(for window: TimeWindow) -> TimeInterval {
        Swift.min(window.duration ?? span, span)
    }

    func latestScroll(length: TimeInterval) -> Date {
        clampedScroll(domainEnd.addingTimeInterval(-length), length: length)
    }

    func clampedScroll(_ position: Date, length: TimeInterval) -> Date {
        let latest = domainEnd.addingTimeInterval(-length)
        if latest <= start { return start }
        return Swift.min(Swift.max(position, start), latest)
    }
}

struct PlottedSeries: Identifiable {
    let id: String
    let points: [GraphPoint]
    let color: Color
    /// Facteur appliqué aux valeurs de l'axe de droite pour les ramener à l'échelle de gauche.
    let scale: Double
    let filled: Bool
}

struct ChartPlot {
    let series: [PlottedSeries]
    let yScale: ValueAxisScale
    /// Graduations de l'axe de droite (vide s'il n'y a pas de série à droite).
    let rightTicks: [Double]
    let rightFactor: Double

    static let empty = ChartPlot(series: [], yScale: ValueAxisScale.nice(min: 0, max: 1), rightTicks: [], rightFactor: 1)

    static func make(
        left: [ChartSeries],
        right: [ChartSeries],
        bounds: ChartBounds,
        length: TimeInterval,
        anchorIndex: Int
    ) -> ChartPlot {
        // Échelle calculée sur toutes les données (elle ne bouge pas pendant le défilement)
        let leftValues = left.flatMap { series in series.points.map { $0.quantity } }
        let yScale = ValueAxisScale.nice(min: leftValues.min() ?? 0, max: leftValues.max() ?? 0)

        var rightFactor = 1.0
        var rightTicks: [Double] = []
        if !right.isEmpty {
            let rightMax = right.flatMap { series in series.points.map { $0.quantity } }.max() ?? 0
            let positiveSteps = Swift.max(1, Int((yScale.upper / yScale.step).rounded()))
            let rightStep = ValueAxisScale.niceStep(Swift.max(rightMax, 0) / Double(positiveSteps))
            rightFactor = yScale.step / rightStep
            rightTicks = yScale.ticks
        }

        // Seule la partie autour de la zone visible est tracée (performances)
        let anchor = bounds.start.addingTimeInterval(Double(anchorIndex) * length)
        let rangeStart = anchor.addingTimeInterval(-length)
        let rangeEnd = anchor.addingTimeInterval(3 * length)
        let bucket = length / 200

        var plotted: [PlottedSeries] = []
        for series in left {
            plotted.append(PlottedSeries(
                id: series.id,
                points: visiblePoints(series.points, from: rangeStart, to: rangeEnd, bucket: bucket),
                color: series.color,
                scale: 1,
                filled: series.filled
            ))
        }
        for series in right {
            plotted.append(PlottedSeries(
                id: series.id,
                points: visiblePoints(series.points, from: rangeStart, to: rangeEnd, bucket: bucket),
                color: series.color,
                scale: rightFactor,
                filled: series.filled
            ))
        }
        return ChartPlot(series: plotted, yScale: yScale, rightTicks: rightTicks, rightFactor: rightFactor)
    }

    /// Points de [from, to] (plus un voisin de chaque côté), sous-échantillonnés (min/max par
    /// tranche) quand la zone visible en contient trop.
    static func visiblePoints(_ points: [GraphPoint], from: Date, to: Date, bucket: TimeInterval) -> [GraphPoint] {
        guard !points.isEmpty else { return [] }
        let lower = Swift.max(lowerBound(points, from) - 1, 0)
        let upper = Swift.min(lowerBound(points, to) + 1, points.count)
        guard lower < upper else { return [] }
        return downsample(points[lower..<upper], bucket: bucket)
    }

    /// Premier index dont `timeFrom` est ≥ `date` (points triés).
    private static func lowerBound(_ points: [GraphPoint], _ date: Date) -> Int {
        var low = 0
        var high = points.count
        while low < high {
            let mid = (low + high) / 2
            if points[mid].timeFrom < date {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }

    private static func downsample(_ points: ArraySlice<GraphPoint>, bucket: TimeInterval) -> [GraphPoint] {
        guard bucket > 1_800, points.count > 400, let firstPoint = points.first else {
            return Array(points)
        }
        let origin = firstPoint.timeFrom
        var result: [GraphPoint] = []
        result.reserveCapacity(points.count / 2)
        var currentBucket = -1
        var low = firstPoint
        var high = firstPoint
        for point in points {
            let index = Int(point.timeFrom.timeIntervalSince(origin) / bucket)
            if index != currentBucket {
                if currentBucket >= 0 {
                    appendExtremes(low, high, to: &result)
                }
                currentBucket = index
                low = point
                high = point
            } else {
                if point.quantity < low.quantity { low = point }
                if point.quantity > high.quantity { high = point }
            }
        }
        appendExtremes(low, high, to: &result)
        return result
    }

    private static func appendExtremes(_ first: GraphPoint, _ second: GraphPoint, to result: inout [GraphPoint]) {
        if first.timeFrom == second.timeFrom {
            result.append(first)
        } else if first.timeFrom < second.timeFrom {
            result.append(first)
            result.append(second)
        } else {
            result.append(second)
            result.append(first)
        }
    }
}

/// Mémorise les points tracés : ils ne sont recalculés que si les données, le zoom ou la
/// tranche de défilement changent (équivalent des `remember(...)` Compose).
final class ChartPlotCache {
    private struct SeriesSignature: Equatable {
        let id: String
        let count: Int
        let first: Date?
        let last: Date?
        let total: Double

        init(_ series: ChartSeries) {
            id = series.id
            count = series.points.count
            first = series.points.first?.timeFrom
            last = series.points.last?.timeFrom
            total = series.points.reduce(0) { $0 + $1.quantity }
        }
    }

    private struct Key: Equatable {
        let left: [SeriesSignature]
        let right: [SeriesSignature]
        let start: Date
        let length: TimeInterval
        let anchorIndex: Int
    }

    private var key: Key?
    private var cached = ChartPlot.empty

    func plot(
        left: [ChartSeries],
        right: [ChartSeries],
        bounds: ChartBounds,
        length: TimeInterval,
        scrollPosition: Date
    ) -> ChartPlot {
        let safeLength = Swift.max(length, 60)
        let offset = Swift.max(scrollPosition.timeIntervalSince(bounds.start), 0)
        let anchorIndex = Int(offset / safeLength)
        let newKey = Key(
            left: left.map { SeriesSignature($0) },
            right: right.map { SeriesSignature($0) },
            start: bounds.start,
            length: safeLength,
            anchorIndex: anchorIndex
        )
        if newKey == key {
            return cached
        }
        let plot = ChartPlot.make(left: left, right: right, bounds: bounds, length: safeLength, anchorIndex: anchorIndex)
        key = newKey
        cached = plot
        return plot
    }
}

/// Graduations « rondes » (1, 2, 5 × 10ⁿ) d'un axe des valeurs.
struct ValueAxisScale: Equatable {
    let lower: Double
    let upper: Double
    let step: Double
    let ticks: [Double]

    static func nice(min minValue: Double, max maxValue: Double, targetSteps: Int = 4) -> ValueAxisScale {
        var lower = Swift.min(0, minValue)
        var upper = Swift.max(0, maxValue)
        if upper - lower < 1e-9 {
            upper = lower + 1
        }
        let step = niceStep((upper - lower) / Double(Swift.max(targetSteps, 1)))
        lower = (lower / step).rounded(.down) * step
        upper = (upper / step).rounded(.up) * step
        var ticks: [Double] = []
        var index = 0
        while true {
            let tick = lower + Double(index) * step
            if tick > upper + step * 0.001 { break }
            ticks.append(tick)
            index += 1
        }
        return ValueAxisScale(lower: lower, upper: upper, step: step, ticks: ticks)
    }

    static func niceStep(_ raw: Double) -> Double {
        guard raw > 0, raw.isFinite else { return 1 }
        let magnitude = pow(10, log10(raw).rounded(.down))
        let fraction = raw / magnitude
        let nice: Double
        if fraction <= 1 {
            nice = 1
        } else if fraction <= 2 {
            nice = 2
        } else if fraction <= 5 {
            nice = 5
        } else {
            nice = 10
        }
        return nice * magnitude
    }
}
