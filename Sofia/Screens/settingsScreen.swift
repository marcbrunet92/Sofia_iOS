import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            Text("Réglages")
                .navigationTitle("Réglages")
        }
    }
}
