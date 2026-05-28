import SwiftUI

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
