import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SofiaViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    if let err = vm.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(err).font(.caption)
                            Spacer()
                            Button("OK") { vm.errorMessage = nil }
                                .font(.caption)
                        }
                        .padding(10)
                        .background(Color.yellow.opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 10))
                    }

                    TotalProductionCard(vm: vm)

                    BMUGridView(vm: vm)

                    ProductionChartView(vm: vm)

                    TimestampsView(vm: vm)
                }
                .padding(.horizontal, 16)   // ← les marges gauche/droite
                .padding(.vertical, 8)
            }
            .navigationTitle("Sofia Wind Farm")
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
            .task { await vm.refresh() }
        }
    }
}

// MARK: - Total production card
struct TotalProductionCard: View {
    @ObservedObject var vm: SofiaViewModel
    private var capacityMW: Double { 1400 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOTAL PRODUCTION")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .kerning(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(vm.totalMW, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("MW")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // Capacity bar
            VStack(alignment: .leading, spacing: 4) {
                let pct = min(vm.totalMW / capacityMW, 1.0)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.15))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * pct)
                            .animation(.spring(), value: pct)
                    }
                }
                .frame(height: 10)

                Text("Capacity factor: \(pct, format: .percent.precision(.fractionLength(1)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)  // ← prend toute la largeur
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Per-BMU grid (2 colonnes fixes)
struct BMUGridView: View {
    @ObservedObject var vm: SofiaViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(BMU.allCases, id: \.rawValue) { bmu in
                BMUCard(name: bmu.displayName,
                        mw: vm.perBMU[bmu.rawValue] ?? 0)
            }
        }
    }
}

struct BMUCard: View {
    let name: String
    let mw: Double

    private var statusColor: Color {
        mw > 10 ? .green : mw > 0 ? .yellow : .gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.8), radius: 4)
                Text(name)
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(mw, format: .number.precision(.fractionLength(1)))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text("MW")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)  // ← important
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(statusColor.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Timestamps
struct TimestampsView: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        VStack(spacing: 10) {
            timestampRow(icon: "antenna.radiowaves.left.and.right",
                         label: "Données API", date: vm.lastAPIUpdate)
            Divider()
            timestampRow(icon: "clock.arrow.circlepath",
                         label: "Dernière mise à jour", date: vm.lastFetch)
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

#Preview {
    ContentView()
}	
