import SwiftUI

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
