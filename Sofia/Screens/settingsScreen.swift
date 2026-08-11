import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Data source") {
                    Toggle("Test mode (T_HEYM11)", isOn: $vm.testMode)
                    Text(vm.mode.displayName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Refresh") {
                    Button("Refresh now") {
                        Task {
                            await vm.refresh()
                        }
                    }
                    .disabled(vm.isLoading)
                }
            }
            .navigationTitle("Réglages")
        }
    }
}
