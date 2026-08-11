import SwiftUI
import Charts
import SofiaCore

struct PNView: View {
    @EnvironmentObject private var vm: SofiaViewModel

    private var filteredPoints: [GraphPoint] {
        guard let snapshot = vm.productionSnapshot else { return [] }
        return filterPoints(snapshot.points, window: vm.selectedTimeWindow)
    }

    var body: some View {
        if let snapshot = vm.productionSnapshot {
            VStack(alignment: .leading, spacing: 16) {
                Gauge(value: snapshot.currentMw, in: 0...vm.mode.capacityMW) {
                    Text("Output")
                } currentValueLabel: {
                    Text("\(snapshot.currentMw, specifier: "%.0f") MW")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(vm.mode.capacityMW, specifier: "%.0f")")
                }
                .gaugeStyle(.accessoryCircular)
                .frame(maxWidth: .infinity)

                PNTimeWindowPicker(window: $vm.selectedTimeWindow)

                if filteredPoints.isEmpty {
                    EmptyStateCard()
                } else {
                    Chart(filteredPoints) { point in
                        LineMark(
                            x: .value("Time", point.timeFrom),
                            y: .value("MW", point.quantity)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 6)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(shortAxisFormatter(for: vm.selectedTimeWindow).string(from: date))
                                }
                            }
                        }
                    }
                    .frame(height: 230)
                }

                PNRecordsCard(top: snapshot.topProduction)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Latest data: \(pnDate(snapshot.latestDataTimestamp))")
                    Text("Last fetch: \(pnDate(vm.lastFetch))")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        } else {
            EmptyStateCard()
        }
    }
}

private struct PNTimeWindowPicker: View {
    @Binding var window: TimeWindow

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeWindow.allCases, id: \.self) { option in
                    Button(option.label) {
                        window = option
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(window == option ? .accentColor : .gray)
                }
            }
        }
    }
}

private struct PNRecordsCard: View {
    let top: TopWindows

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Records")
                .font(.headline)

            pnRow("7d", top.last7Days)
            pnRow("30d", top.last30Days)
            pnRow("90d", top.last90Days)
            pnRow("All", top.allTime)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func pnRow(_ label: String, _ point: TopPoint) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(point.maxQuantity, specifier: "%.0f") MW")
            Text(pnDate(point.maxDate))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

private func pnDate(_ date: Date?) -> String {
    guard let date else { return "—" }
    return date.formatted(date: .abbreviated, time: .shortened)
}
