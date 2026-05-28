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

#Preview {
    ContentView()
}
