import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage = vm.errorMessage {
                        ErrorBanner(text: errorMessage) {
                            vm.dismissError()
                        }
                    }

                    Picker("Panel", selection: $vm.dashboardPanel) {
                        ForEach(SofiaViewModel.DashboardPanel.allCases, id: \.self) { panel in
                            Text(panel.title).tag(panel)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch vm.dashboardPanel {
                    case .production:
                        PNView()
                    case .realOutput:
                        B1610View()
                    }

                    InfoCard(text: vm.mode.displayName)
                }
                .padding()
            }
            .refreshable { await vm.refresh() }
            .navigationTitle("Production")
        }
    }
}
