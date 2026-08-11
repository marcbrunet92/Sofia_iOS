import SwiftUI
import Charts
import SofiaCore

struct B1610View: View {
    @EnvironmentObject private var vm: SofiaViewModel

    private var convertedPoints: [GraphPoint] {
        guard let snapshot = vm.b1610Snapshot else { return [] }
        return snapshot.points.map {
            GraphPoint(seriesId: $0.seriesId, timeFrom: $0.timeFrom, timeTo: $0.timeTo, quantity: b1610ToMw($0.quantity))
        }
    }

    private var filteredPoints: [GraphPoint] {
        filterPoints(convertedPoints, window: vm.selectedTimeWindow)
    }

    var body: some View {
        if let snapshot = vm.b1610Snapshot {
            let currentMw = filteredPoints.last?.quantity ?? 0

            VStack(alignment: .leading, spacing: 16) {
                Gauge(value: currentMw, in: 0...vm.mode.capacityMW) {
                    Text("Real output")
                } currentValueLabel: {
                    Text("\(currentMw, specifier: "%.0f") MW")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(vm.mode.capacityMW, specifier: "%.0f")")
                }
                .gaugeStyle(.accessoryCircular)
                .frame(maxWidth: .infinity)

                B1610TimeWindowPicker(window: $vm.selectedTimeWindow)

                if filteredPoints.isEmpty {
                    EmptyStateCard()
                } else {
                    Chart(filteredPoints) { point in
                        AreaMark(
                            x: .value("Time", point.timeFrom),
                            y: .value("MW", point.quantity)
                        )
                        .foregroundStyle(.green.opacity(0.25))

                        LineMark(
                            x: .value("Time", point.timeFrom),
                            y: .value("MW", point.quantity)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green)
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

                B1610RecordsCard(top: snapshot.topB1610)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Latest data: \(b1610Date(snapshot.latestDataTimestamp))")
                    Text("Last fetch: \(b1610Date(vm.lastFetch))")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        } else {
            EmptyStateCard()
        }
    }
}

private struct B1610TimeWindowPicker: View {
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

private struct B1610RecordsCard: View {
    let top: TopWindows

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Records")
                .font(.headline)

            b1610Row("7d", top.last7Days)
            b1610Row("30d", top.last30Days)
            b1610Row("90d", top.last90Days)
            b1610Row("All", top.allTime)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func b1610Row(_ label: String, _ point: TopPoint) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(b1610ToMw(point.maxQuantity), specifier: "%.0f") MW")
            Text(b1610Date(point.maxDate))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

private func b1610ToMw(_ quantity: Double) -> Double {
    quantity * 2
}

private func b1610Date(_ date: Date?) -> String {
    guard let date else { return "—" }
    return date.formatted(date: .abbreviated, time: .shortened)
}
