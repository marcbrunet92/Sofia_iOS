import SwiftUI
import Charts
import SofiaCore

struct WeatherView: View {

    @EnvironmentObject var vm: SofiaViewModel

    private var filteredPoints: [GraphPoint] {
        guard let snapshot = vm.weatherSnapshot else { return [] }
        return filterPoints(snapshot.points, window: vm.selectedTimeWindow)
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

                    if let snapshot = vm.weatherSnapshot {
                        DefinitionCard(
                            title: "Current wind speed",
                            text: snapshot.latestWindSpeed.map { "\($0, specifier: "%.1f") m/s" } ?? "—"
                        )

                        WeatherTimeWindowPicker(window: $vm.selectedTimeWindow)

                        if filteredPoints.isEmpty {
                            EmptyStateCard()
                        } else {
                            Chart(filteredPoints) { point in
                                AreaMark(
                                    x: .value("Time", point.timeFrom),
                                    y: .value("Wind", point.quantity)
                                )
                                .foregroundStyle(.orange.opacity(0.25))

                                LineMark(
                                    x: .value("Time", point.timeFrom),
                                    y: .value("Wind", point.quantity)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.orange)
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
                            .frame(height: 260)
                        }

                        InfoCard(text: "Latest data: \(weatherDate(snapshot.latestDataTimestamp))")
                    } else {
                        EmptyStateCard()
                    }
                }
                .padding()
            }
            .refreshable { await vm.refresh() }
            .navigationTitle("Météo")
        }
    }
}

private struct WeatherTimeWindowPicker: View {
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

private func weatherDate(_ date: Date?) -> String {
    guard let date else { return "—" }
    return date.formatted(date: .abbreviated, time: .shortened)
}
