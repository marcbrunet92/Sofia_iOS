import Charts
import Foundation
import SwiftUI
import SofiaCore

/// OutageProfileChart.kt : profil d'un avis REMIT. Capacité disponible en paliers (zone colorée),
/// capacité normale en pointillés et trait « maintenant » quand il tombe dans la période.
struct OutageProfileChart: View {
    let steps: [OutageStep]
    let normalMw: Double?

    private struct Point: Identifiable {
        let id: Int
        let time: Date
        let mw: Double
    }

    var body: some View {
        let points = Self.stepPoints(steps)
        let start = steps.map(\.start).min() ?? Date()
        let end = Swift.max(steps.map(\.end).max() ?? start, start.addingTimeInterval(60))
        let top = Swift.max(steps.map(\.capacityMw).max() ?? 0, normalMw ?? 0, 1) * 1.15
        let now = Date()

        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Time", point.time),
                    yStart: .value("Base", 0.0),
                    yEnd: .value("MW", point.mw)
                )
                .foregroundStyle(SofiaColors.primary.opacity(0.2))
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("MW", point.mw)
                )
                .foregroundStyle(SofiaColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            if let normalMw {
                RuleMark(y: .value("Normal", normalMw))
                    .foregroundStyle(SofiaColors.outlineVariant)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(verbatim: L10n.format("remit_profile_normal_format", Int(normalMw.rounded())))
                            .font(SofiaType.labelSmall)
                            .foregroundStyle(SofiaColors.onSurfaceVariant)
                    }
            }
            if now > start && now < end {
                RuleMark(x: .value("Now", now))
                    .foregroundStyle(SofiaColors.error)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("remit_profile_now")
                            .font(SofiaType.labelSmall)
                            .foregroundStyle(SofiaColors.error)
                    }
            }
        }
        .chartXScale(domain: start...end)
        .chartYScale(domain: 0...top)
        .chartXAxis {
            AxisMarks(values: [start, end]) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 180)
    }

    /// Deux points par palier (début et fin à la même capacité) : la courbe dessine des marches.
    private static func stepPoints(_ steps: [OutageStep]) -> [Point] {
        var points: [Point] = []
        for step in steps {
            points.append(Point(id: points.count, time: step.start, mw: step.capacityMw))
            points.append(Point(id: points.count, time: step.end, mw: step.capacityMw))
        }
        return points
    }
}
