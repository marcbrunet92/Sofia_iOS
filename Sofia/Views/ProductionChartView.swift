import SwiftUI
import Charts

struct ProductionChartView: View {
    @ObservedObject var vm: SofiaViewModel

    // Drag offset (panning)
    @State private var dragOffset: Double = 0      // in hours
    @GestureState private var liveOffset: Double = 0

    private var points: [AggregatedPoint] { vm.visibleHistory }

    private var maxMW: Double {
        (points.map(\.totalMw).max() ?? 500) * 1.15
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack {
                Text("Production History")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                // Zoom control
                HStack(spacing: 6) {
                    Text("Window:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach([6.0, 24.0, 48.0, 168.0], id: \.self) { h in
                        Button(hourLabel(h)) {
                            withAnimation { vm.chartHours = h; dragOffset = 0 }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(vm.chartHours == h ? .blue : .gray)
                    }
                }
            }

            if points.isEmpty {
                ContentUnavailableView("No data", systemImage: "waveform.slash",
                    description: Text("No production data for this window"))
                    .frame(height: 220)
            } else {
                Chart(points) { pt in
                    AreaMark(
                        x: .value("Time", pt.time),
                        y: .value("MW", pt.totalMw)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.05)],
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
                    AxisMarks(values: .stride(by: xStride)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: xFormat)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel { Text("\(value.as(Double.self) ?? 0, specifier: "%.0f") MW") }
                    }
                }
                .frame(height: 220)
                .chartScrollableAxes(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers
    private func hourLabel(_ h: Double) -> String {
        switch h {
        case 6:   return "6 h"
        case 24:  return "24 h"
        case 48:  return "48 h"
        case 168: return "7 d"
        default:  return "\(Int(h)) h"
        }
    }

    private var xStride: Calendar.Component {
        vm.chartHours <= 12  ? .hour :
        vm.chartHours <= 72  ? .hour :
                               .day
    }

    private var xFormat: Date.FormatStyle {
        vm.chartHours <= 48
            ? .dateTime.hour().minute()
            : .dateTime.month(.abbreviated).day()
    }
}
