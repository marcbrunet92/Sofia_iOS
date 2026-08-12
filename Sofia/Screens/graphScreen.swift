import SwiftUI
import Charts
import SofiaCore

struct GraphView: View {

    @EnvironmentObject var vm: SofiaViewModel

    private var pnPoints: [GraphPoint] {
        guard let snapshot = vm.productionSnapshot else { return [] }
        return filterPoints(snapshot.points, window: vm.selectedTimeWindow)
    }

    private var b1610Points: [GraphPoint] {
        guard let snapshot = vm.b1610Snapshot else { return [] }
        let converted = snapshot.points.map {
            GraphPoint(seriesId: $0.seriesId, timeFrom: $0.timeFrom, timeTo: $0.timeTo, quantity: $0.quantity * 2)
        }
        return filterPoints(converted, window: vm.selectedTimeWindow)
    }

    private var weatherPoints: [GraphPoint] {
        guard let snapshot = vm.weatherSnapshot else { return [] }
        return filterPoints(snapshot.points, window: vm.selectedTimeWindow)
    }

    private var powerMax: Double {
        let values = pnPoints.map(\.quantity) + b1610Points.map(\.quantity)
        return max(values.max() ?? 1, 1)
    }

    private var windMax: Double {
        max(weatherPoints.map(\.quantity).max() ?? 1, 1)
    }

    private var windScaleFactor: Double {
        powerMax / windMax
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage = vm.errorMessage {
                        ErrorBanner(text: errorMessage) {
                            vm.dismissError()
                        }
                    }

                    GraphSeriesToggle(
                        title: "Wind speed",
                        isOn: $vm.showWindSeries,
                        tint: .orange
                    )
                    GraphSeriesToggle(
                        title: "PN",
                        isOn: $vm.showPnSeries,
                        tint: .blue
                    )
                    GraphSeriesToggle(
                        title: "Real output",
                        isOn: $vm.showB1610Series,
                        tint: .green
                    )

                    GraphTimeWindowPicker(window: $vm.selectedTimeWindow)

                    if pnPoints.isEmpty && b1610Points.isEmpty && weatherPoints.isEmpty {
                        EmptyStateCard()
                    } else {
                        Chart {
                            if vm.showPnSeries {
                                ForEach(pnPoints) { point in
                                    LineMark(
                                        x: .value("Time", point.timeFrom),
                                        y: .value("PN (MW)", point.quantity)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(.blue)
                                }
                            }

                            if vm.showB1610Series {
                                ForEach(b1610Points) { point in
                                    LineMark(
                                        x: .value("Time", point.timeFrom),
                                        y: .value("Real Output (MW)", point.quantity)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(.green)
                                }
                            }

                            if vm.showWindSeries {
                                ForEach(weatherPoints) { point in
                                    LineMark(
                                        x: .value("Time", point.timeFrom),
                                        y: .value("Wind scaled", point.quantity * windScaleFactor)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(.orange)
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel()
                            }

                            AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                                AxisTick()
                                AxisValueLabel {
                                    if let scaled = value.as(Double.self) {
                                        Text("\((scaled / windScaleFactor), specifier: "%.1f")")
                                    }
                                }
                            }
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
                        .frame(height: 300)

                        HStack {
                            Text("Left axis: MW")
                            Spacer()
                            Text("Right axis: m/s")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .refreshable { await vm.refresh() }
            .navigationTitle("Graphes")
        }
    }
}

private struct GraphSeriesToggle: View {
    let title: String
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.subheadline)
        }
        .toggleStyle(.switch)
        .tint(tint)
    }
}

private struct GraphTimeWindowPicker: View {
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
