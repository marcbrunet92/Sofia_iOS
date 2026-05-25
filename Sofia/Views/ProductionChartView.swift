import SwiftUI
import Charts

struct ProductionChartView: View {
    @ObservedObject var vm: SofiaViewModel

    private var points: [AggregatedPoint] { vm.visibleHistory }

    private var maxMW: Double {
        max((points.map(\.totalMw).max() ?? 100) * 1.15, 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header
            HStack {
                Text("Production History")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                // Window selector
                HStack(spacing: 4) {
                    ForEach([6.0, 24.0, 48.0, 168.0, 0.0], id: \.self) { h in
                        Button(hourLabel(h)) {
                            withAnimation { vm.chartHours = h }
                        }
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(vm.chartHours == h ? Color.blue : Color.blue.opacity(0.1),
                                    in: Capsule())
                        .foregroundStyle(vm.chartHours == h ? .white : .blue)
                    }
                }
            }

            if points.isEmpty {
                ContentUnavailableView(
                    "No data",
                    systemImage: "waveform.slash",
                    description: Text("No production data for this window")
                )
                .frame(height: 180)
            } else {
                Chart(points) { pt in
                    AreaMark(
                        x: .value("Time", pt.time),
                        y: .value("MW", pt.totalMw)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Time", pt.time),
                        y: .value("MW", pt.totalMw)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYScale(domain: 0...maxMW)
                .chartXAxis {
                    AxisMarks(values: .stride(by: xStride)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: xFormat)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Double.self) ?? 0, specifier: "%.0f") MW")
                                .font(.system(.caption2, design: .monospaced))
                        }
                    }
                }
                .frame(height: 200)
                .chartScrollableAxes(.horizontal)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private func hourLabel(_ h: Double) -> String {
        switch h {
        case 6:   return "6h"
        case 24:  return "24h"
        case 48:  return "48h"
        case 168: return "7d"
        case 0:   return "All"
        default:  return "\(Int(h))h"
        }
    }

    private var xStride: Calendar.Component {
        vm.chartHours <= 24 ? .hour : .day
    }

    private var xFormat: Date.FormatStyle {
        vm.chartHours <= 48
            ? .dateTime.hour().minute()
            : .dateTime.month(.abbreviated).day()
    }
}
