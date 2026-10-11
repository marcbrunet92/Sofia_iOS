import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de widget/modern/SofiaWidgetCharts.kt (dessiné en SwiftUI au lieu d'un Bitmap).

/// Jauge 270° avec dégradé cyan → bleu → indigo, comme dans l'app.
struct WidgetGauge: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let stroke = size * 0.12
            let progress = min(max(fraction, 0), 1)
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .rotation(.degrees(135))
                    .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: 0.75 * progress)
                        .rotation(.degrees(135))
                        .stroke(
                            AngularGradient(
                                stops: [
                                    Gradient.Stop(color: WidgetPalette.cyan, location: 0),
                                    Gradient.Stop(color: WidgetPalette.blue, location: 0.35),
                                    Gradient.Stop(color: WidgetPalette.indigo, location: 0.75),
                                    Gradient.Stop(color: WidgetPalette.indigo, location: 1),
                                ],
                                center: .center,
                                startAngle: .degrees(135),
                                endAngle: .degrees(495)
                            ),
                            style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                        )
                }
            }
            .padding(stroke / 2 + 1)
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

struct WidgetChartLine {
    let points: [GraphPoint]
    let color: Color
    var filled: Bool = false
}

/// Courbes temporelles (MW) sur [from, to], grille, libellés Y/X et point sur la dernière valeur.
struct WidgetLineChart: View {
    let lines: [WidgetChartLine]
    let from: Date
    let to: Date

    var body: some View {
        GeometryReader { proxy in
            let geometry = WidgetChartGeometry(size: proxy.size, lines: lines, from: from, to: to)
            let timeFormatter = geometry.timeFormatter()
            ZStack(alignment: .topLeading) {
                // Grille + axe Y (0, milieu, max)
                ForEach(0..<3, id: \.self) { index in
                    let value = geometry.yMax * Double(index) / 2
                    let y = geometry.y(value)
                    Path { path in
                        path.move(to: CGPoint(x: geometry.plot.minX, y: y))
                        path.addLine(to: CGPoint(x: geometry.plot.maxX, y: y))
                    }
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    Text(verbatim: String(Int(value)))
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.muted)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(width: max(geometry.plot.minX - 6, 1), alignment: .trailing)
                        .position(x: max(geometry.plot.minX - 6, 1) / 2, y: y)
                }

                // Courbes
                ForEach(lines.indices, id: \.self) { index in
                    let line = lines[index]
                    let points = line.points.filter { $0.timeFrom >= from }
                    if let first = points.first, let last = points.last {
                        if line.filled {
                            geometry.areaPath(points, first: first, last: last)
                                .fill(LinearGradient(
                                    colors: [line.color.opacity(0.4), line.color.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        }
                        geometry.linePath(points)
                            .stroke(line.color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        Circle()
                            .fill(line.color)
                            .frame(width: 7, height: 7)
                            .position(x: geometry.x(last.timeFrom), y: geometry.y(last.quantity))
                    }
                }

                // Axe X : 5 repères
                ForEach(0..<5, id: \.self) { index in
                    let time = geometry.from.addingTimeInterval(geometry.span * Double(index) / 4)
                    let isEdge = index == 0 || index == 4
                    Text(verbatim: timeFormatter.string(from: time))
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.muted)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(
                            width: isEdge ? geometry.plot.width : 90,
                            alignment: index == 0 ? .leading : (index == 4 ? .trailing : .center)
                        )
                        .position(
                            x: isEdge ? geometry.plot.midX : geometry.plot.minX + geometry.plot.width * CGFloat(index) / 4,
                            y: proxy.size.height - 9
                        )
                }
            }
        }
    }
}

struct WidgetChartGeometry {
    let plot: CGRect
    let from: Date
    let span: TimeInterval
    let yMax: Double

    init(size: CGSize, lines: [WidgetChartLine], from: Date, to: Date) {
        plot = CGRect(
            x: 34,
            y: 8,
            width: max(size.width - 34 - 8, 1),
            height: max(size.height - 8 - 20, 1)
        )
        self.from = from
        span = max(to.timeIntervalSince(from), 1)
        let maxValue = lines.flatMap { $0.points }.map { $0.quantity }.max() ?? 0
        yMax = max((maxValue * 1.05 / 100).rounded(.up) * 100, 100)
    }

    func x(_ date: Date) -> CGFloat {
        let ratio = min(max(date.timeIntervalSince(from) / span, 0), 1)
        return plot.minX + CGFloat(ratio) * plot.width
    }

    func y(_ value: Double) -> CGFloat {
        let ratio = min(max(value / yMax, 0), 1)
        return plot.maxY - CGFloat(ratio) * plot.height
    }

    func linePath(_ points: [GraphPoint]) -> Path {
        var path = Path()
        for (index, point) in points.enumerated() {
            let location = CGPoint(x: x(point.timeFrom), y: y(point.quantity))
            if index == 0 {
                path.move(to: location)
            } else {
                path.addLine(to: location)
            }
        }
        return path
    }

    func areaPath(_ points: [GraphPoint], first: GraphPoint, last: GraphPoint) -> Path {
        var path = linePath(points)
        path.addLine(to: CGPoint(x: x(last.timeFrom), y: plot.maxY))
        path.addLine(to: CGPoint(x: x(first.timeFrom), y: plot.maxY))
        path.closeSubpath()
        return path
    }

    func timeFormatter() -> DateFormatter {
        let pattern: String
        if span <= 12 * 3_600 {
            pattern = "HH:mm"
        } else if span <= 3 * 86_400 {
            pattern = "EEE HH:mm"
        } else if span <= 365 * 86_400 {
            pattern = "dd/MM"
        } else {
            pattern = "MM/yy"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = pattern
        return formatter
    }
}

extension LiveData {
    /// Données factices pour l'aperçu de la galerie de widgets.
    static func placeholder(window: TimeInterval = 24 * 3_600, includeActual: Bool = true) -> LiveData {
        let to = Date()
        let from = to.addingTimeInterval(-window)
        let step = max(window / 48, 1_800)
        var committed: [GraphPoint] = []
        var actual: [GraphPoint] = []
        var time = from
        var index = 0.0
        while time <= to {
            let value = 700 + 450 * sin(index / 6)
            committed.append(GraphPoint(id: "SOFIA_TOTAL", timeFrom: time, timeTo: time.addingTimeInterval(step), quantity: value))
            if includeActual {
                actual.append(GraphPoint(id: "SOFIA_TOTAL", timeFrom: time, timeTo: time.addingTimeInterval(step), quantity: value * 0.9))
            }
            time = time.addingTimeInterval(step)
            index += 1
        }
        return LiveData(testMode: false, committed: committed, actual: actual, from: from, to: to, fromCache: false)
    }
}
