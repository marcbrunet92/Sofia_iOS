import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Text("Dashboard")
                Text("Dernière mise à jour : \(vm.lastFetch?.formatted() ?? "-")")
            }
            .navigationTitle("Dashboard")
        }
    }
}
