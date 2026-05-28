import SwiftUI
import SofiaCore

struct RemitView: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoadingRemits && vm.remits.isEmpty {
                    ProgressView("Loading notices…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.remits.isEmpty {
                    ContentUnavailableView(
                        "No REMIT Notices",
                        systemImage: "bell.slash",
                        description: Text("No outage notices found for \(vm.mode.displayName).")
                    )
                } else {
                    List(vm.remits) { remit in
                        NavigationLink(destination: RemitDetailView(remit: remit)) {
                            RemitRowView(remit: remit)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.refreshRemits() }
                }
            }
            .navigationTitle("REMIT Notices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.isLoadingRemits {
                        ProgressView()
                    } else {
                        Button {
                            Task { await vm.refreshRemits() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let err = vm.remitError {
                    Text(err)
                        .font(.caption)
                        .padding(8)
                        .background(.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .padding()
                }
            }
        }
    }
}
