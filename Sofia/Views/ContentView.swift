import SwiftUI
import Charts

// MARK: - Main app with tab navigation
struct ContentView: View {
    @StateObject private var vm = SofiaViewModel()

    var body: some View {
        TabView {
            DashboardView(vm: vm)
                .tabItem {
                    Label("Production", systemImage: "bolt.fill")
                }

            SettingsView(vm: vm)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Test mode banner
                    if vm.testMode {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.black)
                            Text("TEST MODE — displaying T_HEYM11 only")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Error banner
                    if let err = vm.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(err).font(.caption)
                            Spacer()
                            Button("OK") { vm.errorMessage = nil }.font(.caption)
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Ring + total
                    ProductionRingCard(vm: vm)

                    // Chart
                    ProductionChartView(vm: vm)

                    // Timestamps
                    TimestampsView(vm: vm)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle(vm.testMode ? "Test Mode" : "Sofia Wind Farm")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        if vm.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
    }
}

// MARK: - Ring + production card
struct ProductionRingCard: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        VStack(spacing: 20) {

            // Ring gauge
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.blue.opacity(0.12), lineWidth: 22)
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: vm.capacityFactor)
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .indigo],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.0), value: vm.capacityFactor)

                // Center text
                VStack(spacing: 2) {
                    Text(vm.totalMW, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("MW")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(vm.capacityFactor, format: .percent.precision(.fractionLength(1)))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }

            // Capacity label
            Text("of \(Int(vm.capacityMW)) MW capacity")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Timestamps
struct TimestampsView: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        VStack(spacing: 10) {
            timestampRow(icon: "antenna.radiowaves.left.and.right",
                         label: "API data up to", date: vm.lastAPIUpdate)
            Divider()
            timestampRow(icon: "clock.arrow.circlepath",
                         label: "Last fetch", date: vm.lastFetch)

            HStack {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("Auto-refresh every 60 s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func timestampRow(icon: String, label: String, date: Date?) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.blue)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(date.map {
                $0.formatted(.dateTime.day().month(.abbreviated).hour().minute().second())
            } ?? "—")
            .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Settings view
struct SettingsView: View {
    @ObservedObject var vm: SofiaViewModel
    @State private var showVisual = false

    var body: some View {
        NavigationStack {
            Form {
                // Test mode section
                Section {
                    Toggle(isOn: $vm.testMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test Mode")
                                .font(.body)
                            Text("Use T_HEYM11 instead of Sofia BMUs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.yellow)

                    if vm.testMode {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Active — showing HEYM11 data only")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Mode")
                } footer: {
                    Text("In normal mode, the app aggregates the four Sofia BMUs (T_SOFOW-11/12/21/22) as a single 1400 MW wind farm. Test mode displays the adjacent T_HEYM11 unit, which has real production data while Sofia is under construction.")
                }

                // Visualisation section
                Section("Visualisation") {
                    Link(destination: URL(string: "https://sofia.lemarc.fr/visual/pn")!) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundStyle(.blue)
                            Text("Open full PN chart (browser)")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // About section
                Section("About") {
                    LabeledContent("API", value: "sofia.lemarc.fr")
                    LabeledContent("Normal BMUs", value: "SOFOW-11/12/21/22")
                    LabeledContent("Test BMU", value: "HEYM11")
                    LabeledContent("Max capacity", value: "1400 MW")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}
